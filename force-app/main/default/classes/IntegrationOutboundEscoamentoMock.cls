@isTest
global with sharing class IntegrationOutboundEscoamentoMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {

        IntegrationOutboundEscoamento.ModelSAP modelSAP = (IntegrationOutboundEscoamento.ModelSAP)JSON.deserialize(req.getBody(), IntegrationOutboundEscoamento.ModelSAP.class);

        HttpResponse res = new HttpResponse();

        String body;
        if (modelSAP.request == null || modelSAP.request.isEmpty()) {
            body = 'errorXD';
            res.setStatusCode(400);
        } else if (modelSAP.request[0].descricaoTerritorio == 'dataError') {
            body = '{ "response": [ { "type": "E", "message": "Xii, deu ruim!", "sfId": "' + modelSAP.request[0].sfId + '"} ] }';
            res.setStatusCode(200);
        } else if (modelSAP.request[0].descricaoTerritorio == 'requestError') {
            body = 'errorXD';
            res.setStatusCode(400);
        } else {
            body = '{ "response": [ { "type": "S", "message": "Tabela atualizada", "sfId": "' + modelSAP.request[0].sfId + '", "SAPId": "10" } ] }';
            res.setStatusCode(200);
        }
        
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        return res;
    }
}