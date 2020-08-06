@isTest
global with sharing class IntegrationOutboundOrderMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {

        IntegrationOutboundOrder.ModelSAP modelSAP = (IntegrationOutboundOrder.ModelSAP)JSON.deserialize(req.getBody(), IntegrationOutboundOrder.ModelSAP.class);

        HttpResponse res = new HttpResponse();

        String body;
        Integer listSize = modelSAP.item.size();
        if (modelSAP.header.text.textLine == 'dataError') {
            body = '{ "defaultResponse": { "response": [ { "type": "E", "id": "V4", "num": 219, "message": "O doc.vendas  não será modificado" }, { "type": "E", "id": "VP", "num": 200, "message": "Para o cliente 123 não existe nenhum mestre de cliente" } ] } }';
            res.setStatusCode(200);
        } else if (modelSAP.header.text.textLine == 'requestError') {
            res.setStatusCode(400);
        } else {
            body = '{ "defaultResponse": { "document": "0000000050", "response": [ { "type": "S", "id": "V1", "num": 311, "message": "Ordem Venda Stoller 50 foi gravado." }, { "type": "S", "id": "V4", "num": 233, "message": "SALES_CONDITIONS_IN processado com êxito" }, { "type": "S", "id": "V4", "num": 233, "message": "SALES_HEADER_IN processado com êxito" }, { "type": "S", "id": "V4", "num": 233, "message": "SALES_ITEM_IN processado com êxito" } ] }, ' +
            '"schedule": [ { "itmNumber": "000010", "itmNumberSF": "' + modelSAP.item[0].itmNumberSF + '", "scheduleNumber": "0001", "scheduleDate": 20191021, "quantity": "10.000 ", "confirmedQuantity": "10.000 ", "expeditionDate": 20191122, "invoiceDate": 20191126 },' + 
                         ' { "itmNumber": "000020", "itmNumberSF": "' + modelSAP.item[1].itmNumberSF + '", "scheduleNumber": "0001", "scheduleDate": 20191129, "quantity": "10.000 ", "confirmedQuantity": "0.000 ", "expeditionDate": 20191122, "invoiceDate": 20191126 },' +
                         ' { "itmNumber": "000020", "itmNumberSF": "' + modelSAP.item[1].itmNumberSF + '", "scheduleNumber": "0002", "scheduleDate": 20191205, "quantity": "10.000 ", "confirmedQuantity": "8.000 ", "expeditionDate": 20191122, "invoiceDate": 20191126 },' +
                         ' { "itmNumber": "000030", "itmNumberSF": "' + modelSAP.item[2].itmNumberSF + '", "scheduleNumber": "0001", "scheduleDate": 20191205, "quantity": "10.000 ", "confirmedQuantity": "5.000 ", "expeditionDate": 20191122, "invoiceDate": 20191126 },' +
                         ' { "itmNumber": "000040", "itmNumberSF": "' + modelSAP.item[3].itmNumberSF + '", "scheduleNumber": "0001", "scheduleDate": 20191205, "quantity": "10.000 ", "confirmedQuantity": "2.000 ", "expeditionDate": 20191122, "invoiceDate": 20191126 },' +
                         ' { "itmNumber": "000040", "itmNumberSF": "' + modelSAP.item[3].itmNumberSF + '", "scheduleNumber": "0002", "scheduleDate": 20191210, "quantity": "10.000 ", "confirmedQuantity": "3.000 ", "expeditionDate": 20191122, "invoiceDate": 20191126 },' +
                         ' { "itmNumber": "000040", "itmNumberSF": "' + modelSAP.item[3].itmNumberSF + '", "scheduleNumber": "0003", "scheduleDate": 20191211, "quantity": "10.000 ", "confirmedQuantity": "5.000 ", "expeditionDate": 20191122, "invoiceDate": 20191126 },' +
                         ' { "itmNumber": "000050", "itmNumberSF": "' + modelSAP.item[4].itmNumberSF + '", "scheduleNumber": "0001", "scheduleDate": 20191021, "quantity": "1.000 ", "confirmedQuantity": "1.000 ", "expeditionDate": 20191122, "invoiceDate": 20191126 },' +
                         ' { "itmNumber": "000050", "itmNumberSF": "' + modelSAP.item[4].itmNumberSF + '", "scheduleNumber": "0002", "scheduleDate": 20191022, "quantity": "9.000 ", "confirmedQuantity": "9.000 ", "expeditionDate": 20191122, "invoiceDate": 20191126 }] }';
            res.setStatusCode(200);
        }
        
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        return res;
    }
}