f=open('/tmp/foo.txt')

count=0
client=[]
server=[]
for line in f:
    if line[:3] != '===':

        #print('line is',line[:3])
        #if the line is "######",move to the next line with f.readline
        role=(line.split(":",1))[0]
        if role == 'client':
            client.append(line)
        if role == 'server':
            server.append(line)

    else:
        file_client='/tmp/' + 'client' + str(count) + '.txt'
        file_server='/tmp/' + 'server' + str(count) + '.txt'

        f_client=open(file_client,'w')
        f_server=open(file_server,'w')

        f_client.writelines(client)
        f_server.writelines(server)
        print('line is ',line)
        print('created file')
        count += 1
        client=[]
        server=[]
f.close()
f_client.close()
f_server.close()




