// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package lsp

import (
	"bytes"
	"context"
	"fmt"

	"golang.org/x/tools/internal/jsonrpc2"
	"golang.org/x/tools/internal/lsp/protocol"
	"golang.org/x/tools/internal/lsp/source"
	"golang.org/x/tools/internal/lsp/telemetry"
	"golang.org/x/tools/internal/span"
	errors "golang.org/x/xerrors"
)

func (s *Server) didOpen(ctx context.Context, params *protocol.DidOpenTextDocumentParams) error {
	// Confirm that the file's language ID is related to Go.
	uri := span.NewURI(params.TextDocument.URI)
	return s.didModifyFile(ctx, source.FileModification{
		URI:        uri,
		Action:     source.Open,
		Version:    params.TextDocument.Version,
		Text:       []byte(params.TextDocument.Text),
		LanguageID: params.TextDocument.LanguageID,
	})
}

func (s *Server) didSave(ctx context.Context, params *protocol.DidSaveTextDocumentParams) error {
	return s.didModifyFile(ctx, source.FileModification{
		URI:     span.NewURI(params.TextDocument.URI),
		Action:  source.Save,
		Version: params.TextDocument.Version,
		Text:    []byte(params.Text),
	})
}

func (s *Server) didClose(ctx context.Context, params *protocol.DidCloseTextDocumentParams) error {
	return s.didModifyFile(ctx, source.FileModification{
		URI:     span.NewURI(params.TextDocument.URI),
		Action:  source.Close,
		Version: -1,
		Text:    nil,
	})
}

func (s *Server) didChange(ctx context.Context, params *protocol.DidChangeTextDocumentParams) error {
	uri := span.NewURI(params.TextDocument.URI)
	text, err := s.changedText(ctx, uri, params.ContentChanges)
	if err != nil {
		return err
	}
	return s.didModifyFile(ctx, source.FileModification{
		URI:     uri,
		Action:  source.Change,
		Version: params.TextDocument.Version,
		Text:    text,
	})
}

// didModifyFile propagates the information about the file modification
// to the cache layer and runs diagnostics.
//
// TODO(rstambler): This function should be mostly unnecessary once we unify the methods
// for making changes to a file in internal/lsp/cache.
func (s *Server) didModifyFile(ctx context.Context, c source.FileModification) error {
	ctx = telemetry.URI.With(ctx, c.URI)

	view, err := s.session.ViewOf(c.URI)
	if err != nil {
		return err
	}
	switch c.Action {
	case source.Open:
		kind := source.DetectLanguage(c.LanguageID, c.URI.Filename())
		if kind == source.UnknownKind {
			return errors.Errorf("didModifyFile: unknown file kind for %s", c.URI)
		}
		if err := s.session.DidOpen(ctx, c.URI, kind, c.Version, c.Text); err != nil {
			return err
		}
	case source.Change:
		view.SetContent(ctx, c.URI, c.Version, c.Text)

		// Ideally, we should be able to specify that a generated file should be opened as read-only.
		// Tell the user that they should not be editing a generated file.
		if s.wasFirstChange(c.URI) && source.IsGenerated(ctx, view, c.URI) {
			s.client.ShowMessage(ctx, &protocol.ShowMessageParams{
				Message: fmt.Sprintf("Do not edit this file! %s is a generated file.", c.URI.Filename()),
				Type:    protocol.Warning,
			})
		}
	case source.Save:
		s.session.DidSave(c.URI, c.Version)
	case source.Close:
		s.session.DidClose(c.URI)
		view.SetContent(ctx, c.URI, c.Version, c.Text)
	}

	// We should run diagnostics after opening or changing a file.
	switch c.Action {
	case source.Open, source.Change:
		go s.diagnoseFile(view.Snapshot(), c.URI)
	}
	return nil
}

func (s *Server) wasFirstChange(uri span.URI) bool {
	if s.changedFiles == nil {
		s.changedFiles = make(map[span.URI]struct{})
	}
	_, ok := s.changedFiles[uri]
	return ok
}

func (s *Server) changedText(ctx context.Context, uri span.URI, changes []protocol.TextDocumentContentChangeEvent) ([]byte, error) {
	if len(changes) == 0 {
		return nil, jsonrpc2.NewErrorf(jsonrpc2.CodeInternalError, "no content changes provided")
	}

	// Check if the client sent the full content of the file.
	// We accept a full content change even if the server expected incremental changes.
	if len(changes) == 1 && changes[0].Range == nil && changes[0].RangeLength == 0 {
		return []byte(changes[0].Text), nil
	}

	// We only accept an incremental change if that's what the server expects.
	if s.session.Options().TextDocumentSyncKind == protocol.Full {
		return nil, errors.Errorf("expected a full content change, received incremental changes for %s", uri)
	}

	return s.applyIncrementalChanges(ctx, uri, changes)
}

func (s *Server) applyIncrementalChanges(ctx context.Context, uri span.URI, changes []protocol.TextDocumentContentChangeEvent) ([]byte, error) {
	content, _, err := s.session.GetFile(uri, source.UnknownKind).Read(ctx)
	if err != nil {
		return nil, jsonrpc2.NewErrorf(jsonrpc2.CodeInternalError, "file not found (%v)", err)
	}
	for _, change := range changes {
		// Make sure to update column mapper along with the content.
		converter := span.NewContentConverter(uri.Filename(), content)
		m := &protocol.ColumnMapper{
			URI:       uri,
			Converter: converter,
			Content:   content,
		}
		if change.Range == nil {
			return nil, jsonrpc2.NewErrorf(jsonrpc2.CodeInternalError, "unexpected nil range for change")
		}
		spn, err := m.RangeSpan(*change.Range)
		if err != nil {
			return nil, err
		}
		if !spn.HasOffset() {
			return nil, jsonrpc2.NewErrorf(jsonrpc2.CodeInternalError, "invalid range for content change")
		}
		start, end := spn.Start().Offset(), spn.End().Offset()
		if end < start {
			return nil, jsonrpc2.NewErrorf(jsonrpc2.CodeInternalError, "invalid range for content change")
		}
		var buf bytes.Buffer
		buf.Write(content[:start])
		buf.WriteString(change.Text)
		buf.Write(content[end:])
		content = buf.Bytes()
	}
	return content, nil
}