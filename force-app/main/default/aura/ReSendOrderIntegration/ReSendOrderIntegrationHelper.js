({
    sendIntegration: function (component) {
        debugger;
        component.set("v.Spinner", true);
        var action = component.get("c.sendIntegrationOrder");
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state == 'SUCCESS') {
                var result = response.getReturnValue();
                console.log(result);
                component.set("v.Spinner", false);
                if (result != 'SUCCESS') {
                    component.find("divError").getElement().style.display = 'Block';
                    component.find("errorMsg").getElement().innerHTML = result;
                } else {
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                }
            }
        });
        $A.enqueueAction(action);
    }
})