({
    getuploadedFiles: function (component) {
        component.set("v.Spinner", true);
        var action = component.get("c.getFiles");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state == 'SUCCESS') {
                var result = response.getReturnValue();
                component.set("v.totalPages", Math.ceil(response.getReturnValue().length / component.get("v.pageSize")));
                component.set("v.files", result);
                component.set("v.currentPageNumber", 1);
                component.set("v.hasFiles", result.length > 0? true : false);
                
                var data = [];
                var pageNumber = component.get("v.currentPageNumber");
                var pageSize = component.get("v.pageSize");
                var allData = component.get("v.files");
                var x = (pageNumber - 1) * pageSize;

                //creating data-table data
                for (; x <= (pageNumber) * pageSize; x++) {
                    if (allData[x]) {
                        data.push(allData[x]);
                    }
                }
                component.set("v.data", data);
                component.set("v.Spinner", false);
            }
        });
        $A.enqueueAction(action);
    },

    verifyCustomerService: function (component) {
        var action = component.get("c.userHasFullAccess");
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS'){
                var result = response.getReturnValue();
                component.set("v.userHasFullAccess", result);
            }
        });
        $A.enqueueAction(action);
    },

    delUploadedfiles: function (component, documentIdsToDelete) {
        var action = component.get("c.deleteFiles");
        var userHasFullAccess = component.get("v.userHasFullAccess");
        action.setParams({
            "opportunityDocumentIdsToDelete": documentIdsToDelete,
            "userHasFullAccess": userHasFullAccess
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state == 'SUCCESS') {
                var result = response.getReturnValue();
                if(!result.hasErrors){
                    component.find('notifLib').showNotice({
                        "variant": "info",
                        "header": "Sucesso!",
                        "message": result.message,
                        closeCallback: function () { }
                    });
                    this.getuploadedFiles(component);
                } else {
                    component.find('notifLib').showNotice({
                                "variant": "error",
                                "header": "Atenção!",
                                "message": result.message,
                                closeCallback: function () { }
                            });
                    component.set("v.Spinner", false);
                }
            }
        });
        $A.enqueueAction(action);
    },

    reattributeFiles: function (component, contentDocumentIds, helper){
        var action = component.get("c.reattributeFiles");
        action.setParams({
            "recordId": component.get("v.recordId"),
            "contentDocumentIds": contentDocumentIds
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state == 'SUCCESS'){
                component.set("v.Spinner", false);
                $A.createComponent("c:DocumentTypeSelect",
                                   { "documentIds": contentDocumentIds },
                function (result, status) {
                    if (status === "SUCCESS") {
                        component.find('overlayLib').showCustomModal({
                            header: "Selecione os Tipos dos Documentos",
                            body: result,
                            showCloseButton: false,
                            cssClass: "myModal",
                            closeCallback: function () {
                                // component.find('notifLib').showNotice({
                                //     "variant": "info",
                                //     "header": "Sucesso",
                                //     "message": "Arquivos carregados com sucesso!",
                                //     closeCallback: function () { }
                                // });
                                helper.getuploadedFiles(component)
                            }
                        })
                    }
                });
            }
        });
        $A.enqueueAction(action);
    },

    valFiles: function (component, contentDocumentIds){
        var action = component.get("c.validateFiles");
        action.setParams({
            "opportunityDocumentIdsToValidate": contentDocumentIds
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state == 'SUCCESS'){
                var result = response.getReturnValue();
                if(!result.hasErrors){
                    component.find('notifLib').showNotice({
                        "variant": "info",
                        "header": "Sucesso!",
                        "message": result.message,
                        closeCallback: function () { }
                    });
                    this.getuploadedFiles(component);
                } else {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Atenção!",
                        "message": result.message,
                        closeCallback: function () { }
                    });
                    component.set("v.Spinner", false);
                }
            }
        });
        $A.enqueueAction(action);
    },

    buildData : function(component, helper) {
        var data = [];
        var pageNumber = component.get("v.currentPageNumber");
        var pageSize = component.get("v.pageSize");
        var allData = component.get("v.files");
        var x = (pageNumber-1)*pageSize;
        
        //creating data-table data
        for(; x<=(pageNumber)*pageSize; x++){
            if(allData[x]){
            	data.push(allData[x]);
            }
        }
        component.set("v.data", data);
        
        helper.generatePageList(component, pageNumber);
    },
    
    /*
     * this function generate page list
     * */
    generatePageList : function(component, pageNumber){
        pageNumber = parseInt(pageNumber);
        var pageList = [];
        var totalPages = component.get("v.totalPages");
        if(totalPages > 1){
            if(totalPages <= 10){
                var counter = 2;
                for(; counter < (totalPages); counter++){
                    pageList.push(counter);
                } 
            } else{
                if(pageNumber < 5){
                    pageList.push(2, 3, 4, 5, 6);
                } else{
                    if(pageNumber>(totalPages-5)){
                        pageList.push(totalPages-5, totalPages-4, totalPages-3, totalPages-2, totalPages-1);
                    } else{
                        pageList.push(pageNumber-2, pageNumber-1, pageNumber, pageNumber+1, pageNumber+2);
                    }
                }
            }
        }
        component.set("v.pageList", pageList);
        component.set("v.Spinner", false);
    }
})