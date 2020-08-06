({
    doInit : function(component, event, helper) {
        component.set("v.Spinner", true);
        window.addEventListener("keydown", function (event) {
            var kcode = event.code;
            if (kcode == 'Escape') {
                event.preventDefault();
                event.stopImmediatePropagation();
            }
        }, true);
        helper.getDocumentPicklist(component, helper); 
        helper.getOpportunityDocuments(component, helper);
    },

    closeModal: function (component, event, helper) {
        helper.cancelNewDocuments(component);
        component.find("overlayLibDemo1").notifyClose();
    },

    saveOpportunityDocuments: function (component, event, helper) {
        helper.saveDocuments(component, helper);
    }, 

    changeOpportunityDocType: function (component, event, helper) {
        helper.changeOpportunityDocumentType(component, event);
    }
})