({
    check: function (component, isCheckIn, latLng) {
        var action = component.get("c.check");
        action.setParams({
            recordId: component.get("v.recordId"),
            isCheckIn: isCheckIn,
            latLng: latLng
        })
        var self = this;
        
        action.setCallback(this, function(resp){
            
            var responseState = resp.getState();
            var toast = $A.get("e.force:showToast");
            
            if (responseState == 'ERROR'){
                var errorMessage = resp.getError()[0].pageErrors.map(a => a.message).join(' - ')
                
                toast.setParams({
                    "type":"error",
                    "title": "Erro",
                    "message": errorMessage
                });
                
            } else if (responseState == 'SUCCESS'){
                toast.setParams({
                    "type":"success",
                    "title": "Show",
                    "message": (isCheckIn? 'Check-in' : 'Check-out') + ' realizado com sucesso.'
                });
            }
            
            component.set('v.processing', false);
            toast.fire();
            $A.get('e.force:refreshView').fire()
        });
        
        $A.enqueueAction(action);
    },
    
    getGeolocationModule: function(){
        var navigator = (window.navigator.geoLocation || window.navigator.geolocation);
        
        if (!navigator){
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type":"error",
                "title": "Erro",
                "message": "A geolocalização não está habilitada para o seu dispositivo."
            });
            
            resultsToast.fire();
        }
        
        return navigator;
    }
})