function Utils(){};

(function(apexController, window, toastr){
    window.request = function(remoteAction, args) {
        return new Promise(function(resolve, reject){
            window.Visualforce.remoting.Manager.invokeAction.call(
                window.Visualforce.remoting.Manager,
                
                remoteAction, 
                ...args,
                function(response, event) {
                    if (event.status){
                        resolve(response)
                    } else {
                        console.log(event)
                        reject(event)
                    }
                }
            );
        })
    };
    
    Utils.approveRecords = function(orderIdToHandle, approve){
        return request(apexController.urls['APPROVE_RECORDS'], [orderIdToHandle, approve]).then(result => {
            if (result.hasError){
                throw new Error(result.message);
            }
            return result;
        }).catch(error => {
            throw new Error(error.message);
        })
    };

    Utils.getBaseData = function () {
        return request(apexController.urls['GET_BASE_DATA'], []).then(result => {
            if (result.hasError) {
                throw new Error(result.message);
            }
            return result;
        }).catch(error => {
            throw new Error(error.message);
        })
    };
    
    Utils.loadRecordsFrom = function (clienteId, rtvName, oppNumber, ordType, ordMotiv, oppObsInter) {
        return request(apexController.urls['GET_RECORDS'], [clienteId, rtvName, oppNumber, ordType, ordMotiv, oppObsInter]).then(result => {
            return result;
        }).catch(error => {
            throw new Error(error.message);
        });
    };

    Utils.getModalData = function (orderId) {
        return request(apexController.urls['GET_MODAL_DATA'], [orderId]).then(result => {
            return result;
        }).catch(error => {
            throw new Error(error.message);
        });
    }

    Utils.handleOrderItems = function (orderItemsToApprove, approveContext, comments) {
        return request(apexController.urls['HANDLE_ORDER_ITEMS'], [orderItemsToApprove, approveContext, comments]).then(result => {
            return result;
        }).catch(error => {
            throw new Error(error.message);
        });
    }
})(window.apexController, window, toastr);