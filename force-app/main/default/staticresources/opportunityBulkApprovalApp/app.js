angular.module('app', ['infinite-scroll'])
    .controller('ItemController', ItemController);

function ItemController($scope) {
    var c = this;
    c.loading = true;
    c.filterShow = false;

    c.itemsChunkSize = 30;

    c.selectedObject = 'Order';

    c.lastLoadedIndex = -1;

    c.allRecords = [];
    c.visibleRecords = [];

    c.markAll = false;
    c.hasRecordsChecked = false;

    c.status = window.apexController.data.status;

    c.orderTypes = ['']; 
    c.orderMotivs = [''];

    c.startDate = '';
    c.endDate = '';
    c.selectedOrderType = '';
    c.selectedHierarchy = '';
    c.orderId = '';

    c.rtvName = '';
    c.oppObsInter = '';
    c.oppNumber = '';
    c.OrderTypeSelected = '';
    c.OrderMotivSelected = '';

    c.modalOppItemsToHandle = [];
    c.modalOppItemsAlreadyHandled = [];
    c.modalOpp = null;

    this.changeSelectedObject = function (prevValue, isFilter) {
        var self = this;
        toastr.clear();

        if(isFilter){
            window.apexController['data'].oppId = '';
        }

        self.loading = true;
        self.reset();
        
        Utils.loadRecordsFrom(Lookups.clienteId, self.rtvName, self.oppNumber, self.OrderTypeSelected, self.OrderMotivSelected, self.oppObsInter).then(result => {
            $scope.$apply(function () {

                var c = $scope.c;
                console.debug('result length ' + result.length);
                console.debug('result ' + result);
                if (!result.length) {
                    toastr.warning('Não foram encontrados oportunidades que atendam ao filtro.');
                } else {

                    if (result[0].hasError) {

                        c.allRecords = [];
                        c.loading = false;

                    } else {
                        result.forEach(item => item.totalPrice = formatMonetary(item.totalPrice, 2));
                        result.forEach(item => item.dateInterest = formatDate(item.dateInterest));
                        
                        c.allRecords = result;
                        c.visibleRecords = result.slice(0, c.itemsChunkSize);
                        c.lastLoadedIndex = c.itemsChunkSize;

                        self.updateValidity();
                        if (window.apexController['data'].oppId) {
                            var opportunitySelected = result.filter(item => (item.id15 == window.apexController['data'].oppId || item.id == window.apexController['data'].oppId));
                            c.openOrderItemsModal(opportunitySelected[0]);
                        }
                        c.loading = false;
                    }
                }
            });
        }).catch(err => {
            toastr.error(`Um erro ocorreu: ${err}`);
        }).then(a => {
            $scope.$apply(function () {
                var c = $scope.c;
                c.loading = false;
            });
        })
    };

    this.reset = function () {
        c.allRecords = [];
        c.visibleRecords = [];
        c.lastLoadedIndex = -1;
    };

    this.getNextRecords = function () {
        var self = this;
        if (self.visibleRecords.length) {
            self.visibleRecords.push(...self.allRecords.slice(self.lastLoadedIndex, self.lastLoadedIndex + self.itemsChunkSize));

            self.lastLoadedIndex += self.itemsChunkSize;
        }
    };

    this.showFilters = function(){
        c.filterShow = !c.filterShow;
        if (c.filterShow){
            document.getElementById('control_menu_accordion').classList.add('slds-is-');
            $(document).ready(function(){
                c.initializeLookups(); 
            });
        } else {
            document.getElementById('control_menu_accordion').classList.remove('slds-is-open');
        }
    }

    this.updateValidity = function (record) {
        c.hasRecordsChecked = !!this.visibleRecords.filter(a => a.checked).length;
    };


    this.updateValidity = function () {
        c.hasRecordsChecked = !!this.visibleRecords.filter(a => a.checked).length;
    };

    this.handleOrder = function (approve) {
        this.loading = true;

        Utils.approveRecords(this.orderId, approve).then(result => {

            toastr.success(`Registro ${result.statusAction} com sucesso.`);

            $scope.$apply(function () {
                var c = $scope.c;
                let ids = result.recordIds;

                c.allRecords = c.allRecords.filter(record => !ids.includes(record.id));
                c.visibleRecords = c.visibleRecords.filter(record => !ids.includes(record.id));
            });

        }).catch(err => {
            toastr.error(`Um erro ocorreu: ${err}`);
        }).then(a => {
            $scope.$apply(function () {
                var c = $scope.c;
                c.closeOrderItemsModal();
                c.loading = false;
            });
        })
    };

    this.markAllRecords = function () {

        this.loading = true;

        c.markAll = !c.markAll;
        this.visibleRecords.forEach(record => record.checked = c.markAll);

        this.loading = false;

        this.updateValidity();
    };

    this.initializeLookups = function () {
        Lookups.initializeLookups();
    }

    this.getBaseData = function () {

        Utils.getBaseData().then(result => {
            $scope.$apply(function () {
                var c = $scope.c;

                c.orderTypes.push(...result.orderTypes);
                c.orderMotivs.push(...result.orderMotivs);
            });
        }).catch(err => {
            toastr.error(`Um erro ocorreu: ${err}`);
        }).then(a => {
            $scope.$apply(function () {
                var c = $scope.c;
                c.loading = false;
            });
        })
    };

    this.openOrderItemsModal = function (order) {

        var self = this;

        self.orderId = order.id;

        Utils.getModalData(self.orderId).then(result => {
            $scope.$apply(function () {
                var c = $scope.c;
                
                result.orderItemsToHandle.forEach(function(item){ 
                    item.salesPrice = (item.currencyCoin == 'BRL' ? 'R$ ' : 'USD ') + formatMonetary(item.salesPrice, 2);    
                    item.discountGranted = formatMonetary(item.discountGranted, 2);
                    item.discountExcess = formatMonetary(item.discountExcess, 2);                
                });

                result.orderItemsAlreadyHandled.forEach(function(item){ 
                    item.salesPrice = (item.currencyCoin == 'BRL' ? 'R$ ' : 'USD ') + formatMonetary(item.salesPrice, 2);    
                    item.discountGranted = formatMonetary(item.discountGranted, 2);
                    item.discountExcess = formatMonetary(item.discountExcess, 2);                
                });

                c.modalOppItemsToHandle = result.orderItemsToHandle;
                c.modalOppItemsAlreadyHandled = result.orderItemsAlreadyHandled;
                c.modalOpp = result;

                // document.getElementById('orderItemsModal')['innerHTML'] = modalHTML;
                document.getElementById('orderItemsModal').classList.remove('hidden');
                document.getElementById('orderItemsModal').classList.add('modal-show');
            });
        }).catch(err => {
            toastr.error(`Um erro ocorreu: ${err}`);
        }).then(a => {
            $scope.$apply(function () {
                c.loading = false;
            });
        })

    };

    this.closeOrderItemsModal = function () {

        var self = this;

        self.orderId = null;
        //self.changeSelectedObject(self.selectedObject);

        document.getElementById('orderItemsModal').classList.add('hidden');
        document.getElementById('orderItemsModal').classList.remove('modal-show');
    };

    this.ApproveItems = function (approve) {
        Swal.fire({
            title: 'Deseja continuar?',
            type: 'info',
            text: 'Digite um comentário.',
            input: 'text',
            inputPlaceholder: 'Comentário',
            showCancelButton: true,
            confirmButtonColor: '#3085d6',
            confirmButtonText: (approve ? 'Aprovar!' : 'Reprovar!'),
            cancelButtonText: 'Voltar'
        }).then((result) => {
            if (result.value || result.value == '') {
                this.handleSelectedOrderItems(approve, result.value);
            }
        });
    }
    this.handleSelectedOrderItems = function (approve, txtComents) {

        var self = this;

        self.loading = true;

        Utils.handleOrderItems(self.visibleRecords.filter(a => a.checked).map(a => a.id), approve, txtComents).then(result => {
            $scope.$apply(function () {

                var c = $scope.c;

                if (result[0].hasError && result[0].message != 'Não há Oportunidades em Processo de Aprovação.') {
                    toastr.error(`Um erro ocorreu: ${result[0].message}`);
                } else {
                    toastr.success(`Registros ${approve? 'aprovados' : 'reprovados'} com sucesso.`);
                    if (result[0].message == 'Não há Oportunidades em Processo de Aprovação.') {

                        c.allRecords = [];
                        c.loading = false;

                    } else {

                        result.forEach(item => item.totalPrice = formatMonetary(item.totalPrice, 2));
                        result.forEach(item => item.dateInterest = formatDate(item.dateInterest));
                        
                        c.allRecords = result;
                        c.visibleRecords = result.slice(0, c.itemsChunkSize);
                        c.lastLoadedIndex = c.itemsChunkSize;

                        self.updateValidity();

                        c.loading = false;
                    }
                }
/*
                    c.modalOppItemsToHandle = result.orderItemsToHandle;
                    c.modalOppItemsAlreadyHandled = result.orderItemsAlreadyHandled;
                    c.modalOpp = result;

                }

                c.modalOppItemsToHandle.forEach((orderItem) => {
                    orderItem.checked = false;
                });

                if (finalApprove) {
                    self.closeOrderItemsModal();
                }
                self.hasRecordsChecked = false;
                self.loading = false;*/
            });
        }).catch(err => {
            toastr.error(`Um erro ocorreu: ${err}`);
        }).then(a => {
            $scope.$apply(function () {
                c.loading = false;
                c.hasRecordsChecked = false;
            });
        });
    };

    
    window.onload = function () {
        
        c.loading = false;
        c.changeSelectedObject(c.selectedObject, false);
        c.getBaseData();
        c.initializeLookups();   
    }
}
var CURRENCY_REGEX  = new RegExp('R\\$\\s');
function formatMonetary(v, d) {
    if(v){
        let valueParsed = (typeof v == 'string' ? parseFloat(v) : v);
        return valueParsed.toLocaleString('pt-BR', {
            style: 'currency',
            currency: 'BRL',
            minimumFractionDigits: d,
            maximumFractionDigits: d,
        }).replace(CURRENCY_REGEX, ''); 
    }else{
        return v;
    }
}

function sSize(VAR_text) {
    return (VAR_text < 10 ? '0' + VAR_text : VAR_text)
}

function formatDate(date) {
    if(date){
        if (typeof date == 'string' || typeof date == 'number') {
            date = new Date(date);
        }
        return sSize(date.getUTCDate()) + '/' + sSize(date.getUTCMonth() + 1) + '/' + date.getFullYear();
    }else{
        return date;
    }
}