import json
import sys

fname = sys.argv[1]

of = open(fname + "_detail.csv", "w")

with open(fname + "_detail.out") as f:
    for line in f:
        reqid = line[line.find('req #') + 5: line.find('req #') + 25]
        if line.find('succeeded:') != -1:
            j = line[line.find('succeeded:') + 11:-2]
            if len(j) > 0:
                obj = json.loads(j)
                did = obj["did"]
                if "brand" in obj:
                    brand = obj["brand"]
                else:
                    brand = ''
                if "cu" in obj:
                    cu = obj["cu"]
                else:
                    cu = ''
                if "icc_mcc" in obj:
                    icc_mcc = obj["icc_mcc"]
                else:
                    icc_mcc = ''
                if "icc_mcc2" in obj:
                    icc_mcc2 = obj["icc_mcc2"]
                else:
                    icc_mcc2 = ''
                if "icc_mnc" in obj:
                    icc_mnc = obj["icc_mnc"]
                else:
                    icc_mnc = ''
                if "icc_mnc2" in obj:
                    icc_mnc2 = obj["icc_mnc2"]
                else:
                    icc_mnc2 = ''
                if "net_mcc" in obj:
                    net_mcc = obj["net_mcc"]
                else:
                    net_mcc = ''
                if "net_mcc2" in obj:
                    net_mcc2 = obj["net_mcc2"]
                else:
                    net_mcc2 = ''
                if "net_mnc" in obj:
                    net_mnc = obj["net_mnc"]
                else:
                    net_mnc = ''
                if "net_mnc2" in obj:
                    net_mnc2 = obj["net_mnc2"]
                else:
                    net_mnc2 = ''
                if "lang" in obj:
                    lang = obj["lang"]
                else:
                    lang = ''
                if "model" in obj:
                    model = obj["model"]
                else:
                    model = ''

                of.write("{},{},{},{},{},{},{},{},{},{},{},{},{},{}\n".format(reqid, did, brand, cu, icc_mcc, icc_mcc2, icc_mnc, icc_mnc2, net_mcc, net_mcc2, net_mnc, net_mnc2, lang, model))

of.close()