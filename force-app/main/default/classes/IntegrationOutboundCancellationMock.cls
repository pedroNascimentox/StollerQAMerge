@isTest
global with sharing class IntegrationOutboundCancellationMock implements HttpCalloutMock {
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
            body = '{ "defaultResponse": { "document": 50, "response": [ ' + 
                   '{ "type": "S", "id": "V1", "num": 311, "message": "Ordem Venda Stoller 50 foi gravado." }, ' + 
                   '{ "type": "S", "id": "V4", "num": 233, "message": "SALES_CONDITIONS_IN processado com êxito" }, ' + 
                   '{ "type": "S", "id": "V4", "num": 233, "message": "SALES_HEADER_IN processado com êxito" }, ' + 
                   '{ "type": "S", "id": "V4", "num": 233, "message": "SALES_ITEM_IN processado com êxito" } ] }';
            res.setStatusCode(200);
        }
        
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        return res;
    }
}