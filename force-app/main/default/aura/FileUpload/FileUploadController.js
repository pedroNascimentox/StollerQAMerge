({
    doInit: function (component, event, helper) {
        helper.verifyCustomerService(component);
        helper.getuploadedFiles(component);
    },

    previewFile: function (component, event, helper) {
        var rec_id = event.currentTarget.id;
        $A.get('e.lightning:openFiles').fire({
            recordIds: [rec_id]
        });
    },

    setSelectedOpportunityDocuments: function (component, event, helper) {
        var selectedId = '';
        selectedId = event.getSource().get("v.text");
        if (event.getSource().get("v.value") && component.get("v.selectedOpportunityDocuments").indexOf(selectedId) < 0)
            component.get('v.selectedOpportunityDocuments').push(selectedId);
        else {
            var index = component.get("v.selectedOpportunityDocuments").indexOf(selectedId);
            if (index > -1) {
                component.get("v.selectedOpportunityDocuments").splice(index, 1);
            }
        }
    },

    uploadFinished: function (component, event, helper) {
        component.set("v.Spinner", true);

        var uploadedFiles = event.getParam("files");
        var documentIds = uploadedFiles.map((document) => {
            return document.documentId
        });

        helper.reattributeFiles(component, documentIds, helper);

        // helper.showDocTypeModal(component, documentIds);
        // helper.getuploadedFiles(component);
    },

    // showDocTypeModal: function (component, documentIds) {

    //     debugger;

    //     $A.createComponent("c:DocumentTypeSelect",
    //         { documentIds, documentIds },
    //         function (result, status) {
    //             if (status === "SUCCESS") {
    //                 component.find('overlayLib').showCustomModal({
    //                     header: "Selecione os Tipos dos Documentos",
    //                     body: result,
    //                     showCloseButton: false,
    //                     cssClass: "myModal",
    //                     closeCallback: function () {
    //                         helper.getuploadedFiles(component)
    //                     }
    //                 })
    //             }
    //         });
    // },

    delFiles: function (component, event, helper) {
        component.set("v.Spinner", true);
        var documentIdsToDelete = component.get('v.selectedOpportunityDocuments');
        helper.delUploadedfiles(component, documentIdsToDelete);
    },

    validateDocuments: function (component, event, helper) {
        component.set("v.Spinner", true);
        var documentIdsToValidate = component.get('v.selectedOpportunityDocuments');
        if (documentIdsToValidate.length > 0) {
            helper.valFiles(component, documentIdsToValidate);
        } else {
            component.set("v.Spinner", false);
        }
    },

    onNext: function (component, event, helper) {
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber + 1);
        helper.buildData(component, helper);
    },

    onPrev: function (component, event, helper) {
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber - 1);
        helper.buildData(component, helper);
    },

    processMe: function (component, event, helper) {
        component.set("v.currentPageNumber", parseInt(event.target.name));
        helper.buildData(component, helper);
    },

    onFirst: function (component, event, helper) {
        component.set("v.currentPageNumber", 1);
        helper.buildData(component, helper);
    },

    onLast: function (component, event, helper) {
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.buildData(component, helper);
    }
})