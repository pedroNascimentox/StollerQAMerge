({
    checkIn : function(component, event, helper) {
        component.set('v.processing', true);
        var geolocationModule = helper.getGeolocationModule();
        
        if (geolocationModule){            
            helper.getGeolocationModule().getCurrentPosition(function(position){
                let latLng = [position.coords.latitude, position.coords.longitude];
                
                helper.check(component, true, latLng);
            });
        }
        
    },
    
    checkOut : function(component, event, helper) {
        component.set('v.processing', true);
        var geolocationModule = helper.getGeolocationModule();
        
        if (geolocationModule){    
            helper.getGeolocationModule().getCurrentPosition(function(position){
                let latLng = [position.coords.latitude, position.coords.longitude];
                
                helper.check(component, false, latLng);
            });
        }
    }
})