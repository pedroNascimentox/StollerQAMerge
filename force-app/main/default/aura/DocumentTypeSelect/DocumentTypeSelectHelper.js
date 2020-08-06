({
    getOpportunityDocuments: function (component, helper) {
        var action = component.get("c.getOpportunityDocumentsByDocumentId");
        var contentDocumentIds = component.get("v.documentIds");
        action.setParams({
            "contentDocumentIds": contentDocumentIds
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state == 'SUCCESS') {
                var result = response.getReturnValue();
                component.set("v.documents", result);
                component.set("v.Spinner", false);
            } else {
                component.find('notifLibrary').showNotice({
                    "variant": "error",
                    "header": "Atenção",
                    "message": "Houve um problema ao carregar os documentos da oportunidade na tela!",
                    closeCallback: function () {
                        helper.cancelNewDocuments(component);
                    }
                });
                component.set("v.Spinner", false);
            }
        });
        $A.enqueueAction(action);
    },

    getDocumentPicklist: function (component, helper) {
        var action = component.get("c.getDocumentTypes");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state == 'SUCCESS') {
                var result = response.getReturnValue();
                component.set("v.documentTypes", result);
            } else {
                component.find('notifLibrary').showNotice({
                    "variant": "error",
                    "header": "Atenção",
                    "message": "Houve um problema ao carregar os valores dos tipos de documento da oportunidade na tela!",
                    closeCallback: function () {
                        helper.cancelNewDocuments(component);
                    }
                });
                component.set("v.Spinner", false);
            }
        });
        $A.enqueueAction(action);
    },

    saveDocuments: function (component) {
        component.set("v.Spinner", true);
        var action = component.get("c.saveNewDocumentTypes");
        var opportunityDocuments = component.get("v.documents");

        // if(opportunityDocuments.length <= 0){
        //     component.find('notifLibrary').showNotice({
        //         "variant": "error",
        //         "header": "Atenção",
        //         "message": "Não há documentos da oportunidade na tela! Por favor, clique em fechar e reinicie o processo!",
        //         closeCallback: function () { }
        //     });
        //     component.set("v.Spinner", false);
        // } else 
        
        if (!opportunityDocuments.every(elem => elem.documentType != "")) {
            component.find('notifLibrary').showNotice({
                "variant": "error",
                "header": "Atenção",
                "message": "É necessário selectionar o tipo de documento para todos os documentos!",
                closeCallback: function () { }
            });
            component.set("v.Spinner", false);
        } else {
            action.setParams({
                "opportunityDocuments": opportunityDocuments
            });

            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state == 'SUCCESS') {
                    var result = response.getReturnValue();
                    component.set("v.Spinner", false);
                    component.find("overlayLibDemo1").notifyClose();
                }
            });
            $A.enqueueAction(action);
        }
    },

    cancelNewDocuments: function (component) {
        component.set("v.Spinner", true);
        var action = component.get("c.cancelDocuments");
        var contentDocumentIds = component.get("v.documentIds");
        var opportunityDocuments = component.get("v.documents");
        var opportunityDocumentIds = opportunityDocuments.map((opportunityDocument) => {
            opportunityDocument.opportunityDocumentId
        });
        action.setParams({
            "contentDocumentIds": contentDocumentIds,
            "opportunityDocumentIds": opportunityDocumentIds
        })
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state == 'SUCCESS') {
                var result = response.getReturnValue();
                component.set("v.Spinner", false);
            }
        });
        $A.enqueueAction(action);
    },

    changeOpportunityDocumentType: function (component, event) {
        var opportunityDocuments = component.get("v.documents");
        var targetEventId = event.target.id;
        var opportunityDocument = opportunityDocuments.find(function (element) {
            return element.opportunityDocumentId == targetEventId
        })
        opportunityDocument.documentType = document.getElementById(targetEventId).value;
    },


})