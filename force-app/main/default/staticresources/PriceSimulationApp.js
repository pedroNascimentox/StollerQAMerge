(function () {
    var priceSimulationApp = angular.module('priceSimulationApp', ['ngRoute', 'sf-lookup']);
    
    priceSimulationApp.controller('PriceSimulationCtrl', ['$scope', '$http', '$interval', '$sce', function (scope, $http, $interval, $sce) {

        scope.hasMasterAccess = true;

        scope.containerClass = '';
        scope.summaryVision = false;
        scope.step = {
            showNextStep: false,
            title: '',
            indicator: '',
            quantityStep: 2,
            coords: {
                x: 0,
                y: 0,
                z: 0,
                r: 'M 1 0 A 1 1 0 0 0 0 0 L 0 0'
            },
            calcCoords: function () {
                if (typeof this.indicator != 'number' || typeof this.quantityStep != 'number') {
                    this.coords = {
                        x: 0,
                        y: 0
                    };
                    return false;
                }
                if (this.indicator == this.quantityStep) {
                    this.coords.r = 'M 1 0 A 1 1 0 1 1 1 -2.4492935982947064e-16 L 0 0';
                } else {
                    var percent = (100 - ((this.indicator * 100) / this.quantityStep)) / 100;
                    this.coords = {
                        x: Math.cos(2 * Math.PI * percent),
                        y: Math.sin(2 * Math.PI * percent),
                        z: (percent < 0.5 ? 1 : 0),
                        r: ''
                    };
                    this.coords.r = 'M 1 0 A 1 1 0 ' + this.coords.z + ' 0 ' + this.coords.x + ' ' + this.coords.y + ' L 0 0';
                }
            },
            nextTitle: '',
            actionNextStepText: '',
            actionNextStep: null,
            actionBackStep: null
        };

        scope.trustAsHtml = function (html) {
            return $sce.trustAsHtml(html);
        };

        scope.base = {
            isCustomerSpecific: true,
            priceReferenceDate: new Date(),
            referenceDateFormatted: formatDate(new Date())
        };

        scope.resetParams = function () {
            scope.params = {
                account: null,
                freightType: 'CIF',
                expedition: 'Fracionado',
                priceList: null,
                customerType: null,
                businessPlace: null,
                uf: null,
                territory: null,
                selectedTerritory: null
            };
        };
        
        scope.resetParams();

        scope.generated = false;

        scope.isValid = function(){
            valid = (
                ( //needs change for when not in customer specific mode
                    scope.params.selectedAccount     != null /* && */
                    // scope.params.selectedTerritory
                ) || (
                    scope.params.priceList     != null &&
                    scope.params.customerType  != null &&
                    scope.params.businessPlace != null &&
                    scope.params.uf            != null
                )
            ) && (
                scope.base.referenceDateFormatted != null &&
                // scope.params.freightType          != null &&
                (scope.params.selectedTerritory != null || (scope.isRTV && scope.base.rtvTerritory != null))
            )

            if (!valid) scope.generated = false;
            return valid;
        };

        scope.changeInputMode = function(){
            scope.resetParams();
        }

        scope.init = function(){
            scope.resetParams();
            scope.isLoading = true;

            function finalAction(){
                scope.isLoading = false;
                scope.$apply();
            };
            
            callRemoteAction('OpportunityAppController.getBaseData', function (result, event) {
                if (!result.hasErrors) {
                    scope.base.currencies = result.data.currencies;
                    scope.base.cultures = result.data.cultures;
                    scope.base.orderTypes = result.data.orderTypes;
                    scope.base.expeditions = result.data.shipmentConditions;
                    scope.base.paymentConditions = result.data.paymentConditions;
                    scope.base.salesClassifications = result.data.salesClassifications;
                    scope.base.orderReasons = result.data.orderReasons;
                    scope.base.freightTypes = result.data.freightTypes;
                    
                    scope.params.selectedFreightType = 'CIF'; //scope.base.freightTypes.find(a => a.isDefault);
                    scope.params.selectedExpedition = 'Fracionado'; //scope.base.expeditions.find(a => a.isDefault);

                    callRemoteAction('PricingSimulationAppController.getBaseData', function(result, event){
                        if (!result.hasErrors) {
                            if (!result.data.territories.length) {
                                Log.fire({
                                    message: 'Não existem territórios associados à essa conta.'
                                }, {
                                    code: '9294'
                                });
                            }
                            scope.base.priceLists = result.data.priceLists;
                            scope.params.priceList = scope.base.priceLists[0];
                            scope.base.customerTypes = result.data.customerTypes;
                            result.data.regions.push({'isDefault': false, 'label': 'PY', 'value': 'PY'});
                            scope.base.regions = result.data.regions;
                            scope.base.allTerritories = scope.base.availableTerritories = result.data.territories;
                            
                            if(window.isRTV){
                                scope.base.rtvTerritory = result.data.territories[0];
                            } 

                            scope.base.allRegionals = result.data.regionals;
                            scope.base.allBusinessPlaces = result.data.businessPlaces;
                            scope.hasMasterAccess = window.hasMasterAccess;
                            scope.isRTV = window.isRTV;
                        } else {
                            Log.fire(result, {
                                code: '9293'
                            });
                        }

                        finalAction();
                    });
                } else {
                    Log.fire(result, {
                        code: '9292'
                    });

                    finalAction();
                }
                
                
            });
        }

        scope.getData = function () {
            if (!scope.isLoading){
                scope.isLoading = true;
                var territory;
                if (scope.params.selectedTerritory != null || (scope.isRTV && scope.base.rtvTerritory)) {
                    territory = Object.assign({}, scope.isRTV ? scope.base.rtvTerritory : scope.params.selectedTerritory);
                    delete territory['$$hashKey'];
                }

                if (scope.base.isCustomerSpecific) { //is customer specific
                    callRemoteAction('PricingSimulationAppController.getPrices', {
                        isCustomerSpecific: true,
                        data: {
                            // freightType: scope.params.freightType.value,
                            freightType: 'CIF',
                            accountId: scope.params.selectedAccount.id,
                            businessPlaceId: scope.params.selectedAccount.businessPlace.Id,
                            receiverId: scope.params.selectedAccount.id,
                            territoryData: territory,
                            // shipmentCondition: (scope.params.expedition || {}).value,
                            shipmentCondition: 'Fracionado',
                            isCustomerSpecific: true,
                            priceReferenceDate: scope.base.priceReferenceDate,
                            uf: scope.params.uf,
                            currencyName: scope.params.selectedCurrency.value
                        }
                    }, function (result, event) {
                        if (!result.hasErrors){
                            if (event.status) {
                                
                                scope.base.result = result;
                                
                                scope.base.territoryData = result.data.territoryData;
                                scope.base.priceAppData = result.data.priceAppData;

                                scope.base.currentCurrencyLabel = scope.params.selectedCurrency.label == 'USD' ? 'US$' : 'R$';

                                if (result.data.productsData.length > 0) {
                                    
                                    scope.base.arrProducts = result.data.productsData;
                                } else {
                                    scope.base.arrProducts = [];
                                }

                                location.href = "#/productlist"
                                scope.$apply();
                            
                            } else {
                                scope.$apply();
                                Log.fire(null, {
                                    code: '4644'
                                });
                            }
                        } else {
                            Log.fire(result, {
                                code: '2220'
                            });
                        }
                        scope.isLoading = false;
                        scope.$apply();
                    })
                } else {
                    
                    scope.params.selectedCurrency = scope.params.priceList.value == 'Z4' ? scope.base.currencies.find(a => a.value == 'USD') : scope.base.currencies.find(a => a.value == 'BRL');

                    callRemoteAction('PricingSimulationAppController.getPrices', {
                        isCustomerSpecific: true,
                        data: {
                            freightType:        'CIF', //scope.params.freightType.value,
                            territoryData:      territory,
                            shipmentCondition:  'Fracionado', //(scope.params.expedition || {}).value,
                            isCustomerSpecific: false,
                            // freightType:        scope.params.freightType.value,
                            priceList:          scope.params.priceList.value,
                            customerType:       scope.params.customerType.value,
                            hierarchy:          (scope.params.selectedHierarchy || {}).id,
                            uf:                 scope.params.uf.value,
                            simulationBusinessPlace: scope.params.businessPlace.id, 
                            priceReferenceDate: scope.base.priceReferenceDate,
                            currencyName: scope.params.selectedCurrency.value
                        }
                    }, function (result, event) {
                        if (!result.hasErrors) {
                            if (event.status) {

                                scope.base.result = result;

                                scope.base.territoryData = result.data.territoryData;
                                scope.base.priceAppData = result.data.priceAppData;

                                if (result.data.productsData.length > 0) {

                                    scope.base.arrProducts = result.data.productsData;
                                } else {
                                    scope.base.arrProducts = [];
                                }

                                location.href = "#/productlist"
                                scope.$apply();

                            } else {
                                scope.$apply();
                                Log.fire(null, {
                                    code: '11644'
                                });
                            }
                        } else {
                            Log.fire(result, {
                                code: '11220'
                            });
                        }
                        scope.isLoading = false;
                        scope.$apply();
                    })

                }
            }
        }
    }]);

    priceSimulationApp.controller('ParamsCtrl', ['$scope', function (scope) {
        scope.isCustomerSpecific = true;
        scope.accountTerritories = [];
        scope.businessPlaceFields = ['Codigo__c', 'Descricao__c'];
        scope.businessPlaceFieldsTarget = "code;description;"

        scope.$parent.containerClass = 'params';
        scope.step.title = (scope.oppId > ' ' ? 'Detalhes da ' + scope.oppName : 'Nova Oportunidade');
        scope.step.actionNextStepText = 'Avançar';
        scope.step.indicator = 1;
        scope.step.nextTitle = 'Próximo: Catálogo';
        scope.step.calcCoords();
        scope.step.actionNextStep = function () {
            scope.getData();            
        };
        scope.step.actionBackStep = function () {
            sforce.one.navigateToURL('/006/o');
        };

        scope.step.showNextStep = function () {
            return scope.isValid();
        }

        scope.getRegionalName = function (regional) {
            if (regional){
                var values = [];

                if (regional.name) {
                    values.push(regional.name.trim());
                }
                if (regional.externalId) {
                    values.push(regional.externalId.trim());
                }

                return values.join(' • ');
            }
        }
        
        scope.getBusinessPlaceSubtitle = function (place) {
            if (place){
                if (place.hasOwnProperty('returningFields')){
                    var fields = place.returningFields || {};

                    var values = [];

                    if (fields.code) {
                        values.push(fields.code.trim());
                    }
                    if (fields.description) {
                        values.push(fields.description.trim());
                    }

                    return values.join(' • ');
                } else {

                    let msg = '';

                    if (typeof place.description != 'undefined' && place.description) {
                        msg += place.description;
                    }
                    if (typeof place.code != 'undefined' && place.code) {
                        if (msg > ' ') {
                            msg += ' • ';
                        }
                        msg += place.code;
                    }
                    return msg;
                
                }
            }
        }

        scope.calendarVisibility = {};

        scope.setReferenceDate = function (dt, name) {
            scope.base.priceReferenceDate = dt;
            scope.base.referenceDateFormatted = scope.formatScopeDate(dt);
            scope.calendarVisibility[name] = false;
            scope.$apply();
        };

        scope.hasAccount = function () {
            return scope.params.selectedAccount != null
        };

        scope.hierarchyFilters = [{
            fieldApiName: 'RecordType.DeveloperName',
            operator: 'LIKE',
            value: `\'%Hierarquia%\'`
        }];

        scope.hierarchyFieldsTarget = "Name;ExternalId__c;";

        scope.hierarchyFields = ['externalId__c'];

        scope.getHierarchySubtitle = function (hierarchy) {

            if(hierarchy.hasOwnProperty('returningFields')){
                hierarchy.externalId = hierarchy.returningFields.externalId__c;
            }

            let msg = '';
        
            if (typeof hierarchy.name != 'undefined' && hierarchy.name){
                msg += hierarchy.name;
            }
            if (typeof hierarchy.externalId != 'undefined' && hierarchy.externalId) {
                if (msg > ' ') {
                    msg += ' • ';
                }
                msg += hierarchy.externalId;
            }
            return msg;
        };

        scope.accountReturnedFields = ['CNPJ__c', 'NomeFazenda__c', 'ShippingCity', 'ShippingState', 'ExternalId__c'];

        scope.getAccountSubtitle = function (account) {
            if (account.hasOwnProperty('returningFields')) {
                account.cnpj = account.returningFields.CNPJ__c;
                account.usedName = account.returningFields.NomeFazenda__c;
                account.externalId = account.returningFields.ExternalId__c;
                account.shippingCity = account.returningFields.ShippingCity;
                account.shippingState = account.returningFields.ShippingState;
            }
            let msg = '';
            if (typeof account.externalId != 'undefined' && account.externalId) {
                msg += account.externalId;
            }
            if (typeof account.cnpj != 'undefined' && account.cnpj) {
                if (msg > ' ') {
                    msg += ' • ';
                }
                msg += account.cnpj;
            }
            if (typeof account.usedName != 'undefined' && account.usedName) {
                if (msg > ' ') {
                    msg += ' • ';
                }
                msg += account.usedName;
            }
            if (typeof account.shippingCity != 'undefined' && account.shippingCity) {
                if (msg > ' ') {
                    msg += ' • ';
                }
                msg += account.shippingCity;
                if (typeof account.shippingState != 'undefined' && account.shippingState) {
                    msg += ', ' + account.shippingState;
                }
            }
            return msg;
        };

        scope.updateSelectedAccount = function () {
            if (scope.params.selectedAccount != null){

                if (!scope.params.selectedAccount.territories.length){
                    scope.params.selectedAccount = null;
                    Log.fire({
                        message: 'A conta selecionada não tem nenhum território associado.'
                    });
                }

                scope.accountTerritories = scope.params.selectedAccount.territories;

                if (scope.accountTerritories.length == 1) {
                    scope.params.selectedTerritory = scope.accountTerritories[0];
                }

                if(scope.params.selectedAccount.priceList == 'Z4'){
                    scope.params.selectedCurrency = scope.base.currencies.find(a => a.value == 'USD')
                } else {
                    scope.params.selectedCurrency = scope.base.currencies.find(a => a.value == 'BRL')
                }
                
            } else {
                scope.resetAccount();
            }
        };

        scope.resetAccount = function(){
            scope.accountTerritories = null;
            scope.params.selectedTerritory = null;
        };

        scope.territoryFieldsTarget = "territoryName;externalId;";

        scope.territoryFields = ['name', 'externalId', 'territoryName'];

        scope.getTerritorySubtitle = function (territory) {
            if (territory) {
                if (territory.hasOwnProperty('returningFields')){

                    var fields = territory.returningFields || {};

                    var values = [];

                    if (fields.territoryName) {
                        values.push(fields.territoryName.trim());
                    }
                    if (fields.externalId) {
                        values.push(fields.externalId.trim());
                    }

                    return values.join(' • ');
                }

                let msg = '';

                if (typeof territory.territoryName != 'undefined' && territory.territoryName) {
                    msg += territory.territoryName;
                }
                if (typeof territory.externalId != 'undefined' && territory.externalId) {
                    if (msg > ' ') {
                        msg += ' • ';
                    }
                    msg += territory.externalId;
                }
                return msg;

            }
        }

        scope.updateSelectedTerritory = function () {
            if (scope.params.selectedRegional != null && scope.params.selectedTerritory == null) {
                scope.params.selectedRegional = null;
            } else {
                scope.params.selectedRegional = scope.base.allRegionals.find(a => a.id == scope.params.selectedTerritory.regional)
            }
        }

        scope.updateAvailableTerritories = function (){
            scope.params.selectedTerritory = null;
            if (scope.params.selectedRegional == null) {
                scope.base.availableTerritories = scope.base.allTerritories;
            } else {
                scope.base.availableTerritories = scope.base.allTerritories.filter(a => a.regional == scope.params.selectedRegional.id);
            }
        }

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

        scope.openCalendar = function (name) {
            scope.calendarVisibility[name] = !scope.calendarVisibility[name];
        };

        referenceDate1 = Calendar.create('wrapper-reference-date-a', {
            dates: {},
            initDate: formatDateForm(new Date()),
            isOpen: true,
            name: 'reference-date-a',
            greaterThanInit: false,
            lessThanInit: true,
            weekendAvaliable: true
        }, function (result, name) {
            scope.setReferenceDate(result, name);
        });
        
        referenceDate2 = Calendar.create('wrapper-reference-date-b', {
            dates: {},
            initDate: formatDateForm(new Date()),
            isOpen: true,
            name: 'reference-date-b',
            greaterThanInit: false,
            lessThanInit: true,
            weekendAvaliable: true
        }, function (result, name) {
            scope.setReferenceDate(result, name);
        });

        scope.calendarVisibility[referenceDate1.name] = false;
        scope.calendarVisibility[referenceDate2.name] = false;
    }]);

    priceSimulationApp.config(function ($routeProvider) {
        
        $routeProvider.
        when('/params', {
            templateUrl: window.URLS.priceSimulationAppHeader,
            controller: 'ParamsCtrl'
        })
        .when('/productlist', {
            templateUrl: window.URLS.priceSimulationAppProductList,
            controller: 'ProductCtrl'
        })
        .otherwise({
            redirectTo: '/params'
        });
    });

    priceSimulationApp.controller('SectionCtrl', ['$scope', function (scope) {

        scope.isExpanded = true;
        scope.isHidden = false;

        scope.toggle = function () {
            scope.isExpanded = !scope.isExpanded;
            scope.isHidden = !scope.isHidden;
        };

        scope.init = function (isToggled) {
            isToggled = isToggled == undefined ? true : false;
            scope.isExpanded = isToggled;
            scope.isHidden = !isToggled;
        };

    }]);

    priceSimulationApp.controller('ProductCtrl', ['$scope', '$http', function (scope, http) {

        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.step.title = 'Catálogo';
        scope.step.actionNextStepText = 'Exportar preços';
        scope.step.indicator = 2;
        scope.step.nextTitle = 'Próximo: Quantidade e Preço';
        scope.step.actionNextStep = function () {

            let filteredProducts = scope.base.arrProducts.filter(a => a.inCart);
            
            scope.base.result.data.productsData = filteredProducts.length ? filteredProducts : scope.base.result.data.productsData;
            scope.base.result.data.currencyName = scope.params.selectedCurrency.label;

            scope.base.result.data.productsData.forEach(a => {
                delete a['$$hashKey'];
                delete a['inCart'];
                delete a['details'];
            });

            scope.isLoading = true;

            callRemoteAction('PricingSimulationAppController.getPdfDocument', scope.base.result, function (result, event) {
                scope.isLoading = false;
                if (event.status){
                    if (!result.hasErrors) {
                        Swal.fire({
                            title: 'Exportar',
                            html: 'Selecione uma opção de exportação.',
                            type: 'info',
                            showCancelButton: true,
                            confirmButtonColor: '#3085d6',
                            confirmButtonText: 'PDF',
                            cancelButtonText: 'Excel',
                            allowOutsideClick: false,
                            allowEscapeKey: false
                        }).then((resultPopUp) => {
                            if (resultPopUp.value) {
                                window.open('/apex/PricePdf?id=' + result.documentId);
                            }else {
                                window.open('/apex/PriceExcel?id=' + result.documentId);
                            }
                        });
                    } else {
                        Log.fire(result, {
                            code: '4644'
                        });
                    }
                } else {
                    Log.fire({
                        message: 'Aperte F12 para mais informações.'
                    }, {
                        code: '5656'
                    });
                }

                scope.base.result.data.productsData = scope.base.arrProducts;
                scope.isLoading = false;
                scope.$apply();
            })
        }
        scope.step.actionBackStep = function () {
            location.href = "#/header";
        };
        scope.step.calcCoords();
        scope.step.showNextStep = function () {
            return true;
        };

        scope.termSearch;

        scope.clearSearch = function () {
            scope.termSearch = null;
            document.getElementById('txtTermSearch').focus();
        };

        scope.getPriceList = function (p) {
            return formatMonetary(p.priceList);
        };

        scope.getLastPrice = function (p) {
            return formatMonetary(p.details.details.lastSalesPrice);
        };

        scope.formatPrice = function (price) {
            return formatMonetary(price, 2);
        };

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

    }]);

    
})(); 

function Log() {
    this.showErrorMessage = function (ex, opt) {
        if (typeof ex == 'undefined') {
            ex = {
                message: defaultErrorMessage,
                stackStrace: null
            };
        }
        if (ex == null) {
            ex = {
                message: defaultErrorMessage,
                stackStrace: null
            };
        }
        if (typeof ex.stackStrace == 'undefined') {
            ex.stackStrace = null;
        }
        if (typeof opt == 'undefined') {
            opt = {};
        }
        if (typeof opt.type == 'undefined') {
            opt.type = 'warning';
        }
        if (typeof opt.title == 'undefined') {
            opt.title = 'Oops...';
        }
        if (typeof opt.code == 'undefined') {
            opt.code = null;
        }
        if (typeof opt.open == 'undefined') {
            opt.open = false;
        }
        if (typeof opt.confirmText == 'undefined') {
            opt.confirmText = 'OK';
        }
        if (typeof opt.callback == 'undefined') {
            opt.callback = function (params) {};
        }
        let html = ex.message + ' <br/>';
        let time = (new Date()).getTime();
        if (ex.stackStrace != null) {
            html += '' +
                '<div class="collapsible left">' +
                '   <input type="checkbox" id="log-code-' + time + '" ' + (opt.open ? 'checked="true"' : '') + ' />' +
                '   <div class="collapsible-header">' +
                '       <label for="log-code-' + time + '">' +
                '           <svg class="slds-button__icon collapsible-down" aria-hidden="true">' +
                '               <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevrondown"></use>' +
                '           </svg>' +
                '           <svg class="slds-button__icon collapsible-up" aria-hidden="true">' +
                '               <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevronup"></use>' +
                '           </svg>' +
                '           <small>' + (opt.code != null ? 'CODE: [' + opt.code + ']' : 'Detalhes') + '</small>' +
                '       </label>' +
                '   </div>' +
                '   <div class="collapsible-body">' + ex.stackStrace + '</div>' +
                '</div>';
        } else if (opt.code != null) {
            html += '' +
                '<div class="collapsible">' +
                '   <div class="collapsible-header">' +
                '       <label for="log-code-' + time + '">' +
                '           <small>CODE: [' + opt.code + ']</small>' +
                '       </label>' +
                '   </div>' +
                '</div>';
        }
        Swal.fire({
            type: opt.type,
            title: opt.title,
            html: html,
            confirmButtonText: opt.confirmText
        }).then((result) => {
            opt.callback(result);
        });
    };
}

Log.fire = function (ex, opt) {
    new Log().showErrorMessage(ex, opt);
};

function callRemoteAction(remoteAction, params, callback) {
    Visualforce.remoting.Manager.invokeAction(
        remoteAction, params,
        function (result, event) {
            callback(result, event);
        }, {
            buffer: false,
            escape: false,
            timeout: 300000
        }
    );
}

const Toast = Swal.mixin({
    toast: true,
    position: 'top-end',
    showConfirmButton: false,
    timer: 3000
});

function Log() {
    this.showErrorMessage = function (ex, opt) {
        if (typeof ex == 'undefined') {
            ex = {
                message: defaultErrorMessage,
                stackStrace: null
            };
        }
        if (ex == null) {
            ex = {
                message: defaultErrorMessage,
                stackStrace: null
            };
        }
        if (typeof ex.stackStrace == 'undefined') {
            ex.stackStrace = null;
        }
        if (typeof opt == 'undefined') {
            opt = {};
        }
        if (typeof opt.type == 'undefined') {
            opt.type = 'warning';
        }
        if (typeof opt.title == 'undefined') {
            opt.title = 'Oops...';
        }
        if (typeof opt.code == 'undefined') {
            opt.code = null;
        }
        if (typeof opt.open == 'undefined') {
            opt.open = false;
        }
        if (typeof opt.confirmText == 'undefined') {
            opt.confirmText = 'OK';
        }
        if (typeof opt.callback == 'undefined') {
            opt.callback = function (params) {};
        }
        let html = ex.message + ' <br/>';
        let time = (new Date()).getTime();
        if (ex.stackStrace != null) {
            html += '' +
                '<div class="collapsible left">' +
                '   <input type="checkbox" id="log-code-' + time + '" ' + (opt.open ? 'checked="true"' : '') + ' />' +
                '   <div class="collapsible-header">' +
                '       <label for="log-code-' + time + '">' +
                '           <svg class="slds-button__icon collapsible-down" aria-hidden="true">' +
                '               <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevrondown"></use>' +
                '           </svg>' +
                '           <svg class="slds-button__icon collapsible-up" aria-hidden="true">' +
                '               <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevronup"></use>' +
                '           </svg>' +
                '           <small>' + (opt.code != null ? 'CODE: [' + opt.code + ']' : 'Detalhes') + '</small>' +
                '       </label>' +
                '   </div>' +
                '   <div class="collapsible-body">' + ex.stackStrace + '</div>' +
                '</div>';
        } else if (opt.code != null) {
            html += '' +
                '<div class="collapsible">' +
                '   <div class="collapsible-header">' +
                '       <label for="log-code-' + time + '">' +
                '           <small>CODE: [' + opt.code + ']</small>' +
                '       </label>' +
                '   </div>' +
                '</div>';
        }
        Swal.fire({
            type: opt.type,
            title: opt.title,
            html: html,
            confirmButtonText: opt.confirmText
        }).then((result) => {
            opt.callback(result);
        });
    };
}

Log.fire = function (ex, opt) {
    new Log().showErrorMessage(ex, opt);
};

function sSize(VAR_text) {
    return (VAR_text < 10 ? '0' + VAR_text : VAR_text)
}

function formatDate(date) {
    if (typeof date == 'string') {
        date = new Date(date + 'T12:00');
    }
    if (typeof date == 'number') {
        date = new Date(date);
        return sSize(date.getUTCDate()) + '/' + sSize(date.getUTCMonth() + 1) + '/' + date.getUTCFullYear();
    }
    return sSize(date.getDate()) + '/' + sSize(date.getMonth() + 1) + '/' + date.getFullYear();
}

function formatDateForm(date) {
    if (typeof date == 'string') {
        date = new Date(date + 'T12:00');
    }
    if (typeof date == 'number') {
        date = new Date(date);
        return sSize(date.getUTCFullYear()) + '-' + sSize(date.getUTCMonth() + 1) + '-' + sSize(date.getUTCDate());
    }
    return sSize(date.getFullYear()) + '-' + sSize(date.getMonth() + 1) + '-' + sSize(date.getDate());
}

function areDatesEqual(VAR_d1, VAR_d2) {
    if (typeof VAR_d1 == 'string') {
        VAR_d1 = new Date(VAR_d1 + 'T12:00');
    }
    if (typeof VAR_d1 == 'number') {
        VAR_d1 = new Date(VAR_d1);
    }
    if (typeof VAR_d2 == 'string') {
        VAR_d2 = new Date(VAR_d2 + 'T12:00');
    }
    if (typeof VAR_d2 == 'number') {
        VAR_d2 = new Date(VAR_d2);
    }
    VAR_d1 = VAR_d1.getFullYear() + '-' + VAR_d1.getMonth() + '-' + VAR_d1.getDate();
    VAR_d2 = VAR_d2.getFullYear() + '-' + VAR_d2.getMonth() + '-' + VAR_d2.getDate();
    if (VAR_d1 == VAR_d2) {
        return true;
    }
    return false;
}

function isEqualOrGreaterThan(d1, d2, eq) {
    if (typeof d1 == 'string') {
        d1 = new Date(d1 + 'T12:00');
    }
    if (typeof d1 == 'number') {
        d1 = new Date(d1);
    }
    if (typeof d2 == 'string') {
        d2 = new Date(d2 + 'T12:00');
    }
    if (typeof d2 == 'number') {
        d2 = new Date(d2);
    }

    if (!(d1 instanceof Date) || !(d2 instanceof Date)) {
        return false;
    }

    return d1.getTime() > d2.getTime() || areDatesEqual(d1, d2);
}

function isDateInRange(dt, d1, d2) {
    if (typeof dt == 'string') {
        dt = new Date(dt + 'T12:00');
    }
    if (typeof dt == 'number') {
        dt = new Date(dt);
    }
    if (typeof d1 == 'string') {
        d1 = new Date(d1 + 'T12:00');
    }
    if (typeof d1 == 'number') {
        d1 = new Date(d1);
    }
    if (typeof d2 == 'string') {
        d2 = new Date(d2 + 'T12:00');
    }
    if (typeof d2 == 'number') {
        d2 = new Date(d2);
    }

    if (!(dt instanceof Date) || !(d1 instanceof Date) || !(d2 instanceof Date)) {
        return false;
    }

    return (dt.getTime() > d1.getTime() && dt.getTime() < d2.getTime()) || (areDatesEqual(dt, d1) || areDatesEqual(dt, d2));
}

function compareMonths(VAR_d1, VAR_d2) {
    if (typeof VAR_d1 == 'string') {
        VAR_d1 = new Date(VAR_d1 + 'T12:00');
    }
    if (typeof VAR_d1 == 'number') {
        VAR_d1 = new Date(VAR_d1);
    }
    if (typeof VAR_d2 == 'string') {
        VAR_d2 = new Date(VAR_d2 + 'T12:00');
    }
    if (typeof VAR_d2 == 'number') {
        VAR_d2 = new Date(VAR_d2);
    }
    if (!(VAR_d1 instanceof Date) || !(VAR_d2 instanceof Date)) {
        return false;
    }
    VAR_d1 = VAR_d1.getFullYear() + '-' + VAR_d1.getMonth();
    VAR_d2 = VAR_d2.getFullYear() + '-' + VAR_d2.getMonth();
    if (VAR_d1 == VAR_d2) {
        return true;
    }
    return false;
}

function Calendar() {
    this.initDate = null;
    this.endDate = null;
    this.contextDate = null;
    this.domElement = null;
    this.multiple = false;
    this.selected = [];
    this.dates = [];
    this.avaliable = [];
    this.months = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];

    this.getWeekend = function (dt) {
        if (this.weekendAvaliable) {
            return true;
        }
        let weekendDays = [0, 6];
        if (weekendDays.indexOf(dt.getDay()) > -1) {
            return false;
        }
        return true;
    };

    this.isUnavailableDate = function (dt) {
        if (this.unavailableDates.indexOf(formatDateForm(dt)) > -1) {
            return true;
        }
        return false;
    };

    this.setDaysCalendar = function () {
        var currMonth = null;
        var contextDate = null;
        this.dates = [];
        contextDate = new Date(this.contextDate);
        contextDate.setDate(1);
        currMonth = contextDate.getMonth();
        while (contextDate.getMonth() == currMonth) {
            this.dates.push(new Date(contextDate));
            contextDate.setDate(contextDate.getDate() + 1);
        }
        this.drawCalendar();
    };

    this.initCalendar = function (id, options, callback) {
        var datesArray = [];
        for (var dateKey in options.dates) {
            datesArray.push(new Date(dateKey));
        }
        this.name = options.name ? options.name.toString() : (++Calendar.counter).toString();
        this.endDate = (datesArray.length > 0 ? new Date(Math.max.apply(null, datesArray)) : null);
        this.initDate = (datesArray.length > 0 ? new Date(Math.min.apply(null, datesArray)) : options.initDate);
        this.avaliable = options.dates;
        this.weekendAvaliable = options.weekendAvaliable;
        this.unavailableDates = options.unavailableDates;
        this.isOpen = options.isOpen;
        this.greaterThanInit = options.greaterThanInit;
        this.lessThanInit = options.lessThanInit;
        this.contextDate = new Date(this.initDate);
        this.callback = callback;
        document.getElementById(id).innerHTML = `<table class="calendar calendar-${this.name}"></table>`;

        this.domElement = document.querySelector(`.calendar.calendar-${this.name}`);

        if (typeof this.unavailableDates == 'undefined') {
            this.unavailableDates = [];
        }
        if (this.unavailableDates == null) {
            this.unavailableDates = [];
        }
        if (typeof this.isOpen == 'undefined') {
            this.isOpen = true;
        }
        if (typeof this.greaterThanInit == 'undefined') {
            this.greaterThanInit = true;
        }
        if (typeof this.lessThanInit == 'undefined') {
            this.lessThanInit = !this.greaterThanInit;
        }

        var self = this;
        this.unavailableDates.forEach(function (item, index) {
            self.unavailableDates[index] = formatDateForm(item);
        });

        this.setDaysCalendar();

        return this;
    };

    this.drawCalendar = function () {
        if (this.initDate == 'Invalid Date' ||
            this.endDate == 'Invalid Date' ||
            this.contextDate == 'Invalid Date') {
            return false;
        }
        var html = '' +
            '<tr class="month">' +
            '	<td><div class="previous-month-arrow ' + (this.greaterThanInit ? (compareMonths(this.contextDate, this.initDate) ? 'disabled' : '') : '') + '"><svg class="slds-button__icon" aria-hidden="true"><use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevronleft"></use></svg></div></td>' +
            '	<td colspan="5" id="month">' + this.months[this.contextDate.getMonth()] + ' <small>' + this.contextDate.getFullYear() + '</small></td>' +
            '	<td><div class="next-month-arrow ' + (!this.isOpen ? (compareMonths(this.contextDate, this.endDate) ? 'disabled' : '') : '') + ' ' + (this.lessThanInit ? (compareMonths(this.contextDate, this.initDate) ? 'disabled' : '') : '') + '"><svg class="slds-button__icon" aria-hidden="true"><use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevronright"></use></svg></div></td>' +
            '</tr>' +
            '<tr class="label">' +
            '	<td>D</td>' +
            '	<td>S</td>' +
            '	<td>T</td>' +
            '	<td>Q</td>' +
            '	<td>Q</td>' +
            '	<td>S</td>' +
            '	<td>S</td>' +
            '</tr>' +
            '<tr>';
        var colspan = this.dates[0].getDay();
        var cols = 6;
        var dateFormated = null;
        for (var i = 0; i < this.dates.length; i++) {
            if (colspan > 0 && colspan < 7) {
                html += '' +
                    '<td colspan="' + colspan + '"></td>';
                colspan = 0;
            }
            dateFormated = formatDateForm(this.dates[i]);
            html += '' +
                '	<td>' +
                '       <div class="day-element wrapper ' + (this.selected.indexOf(dateFormated) > -1 ? 'active ' : '') + (areDatesEqual(this.dates[i], new Date()) ? 'today' : '') + (!this.isOpen ? (Object.keys(this.avaliable).length > 0 ? (typeof this.avaliable[dateFormated] == 'undefined' ? ' disabled' : '') : ' disabled') : (this.greaterThanInit ? (isEqualOrGreaterThan(dateFormated, this.initDate) ? '' : ' disabled') : '') + ' ' + (this.lessThanInit ? (isEqualOrGreaterThan(this.initDate, dateFormated) ? '' : ' disabled') : '')) + (this.getWeekend(this.dates[i]) ? '' : ' disabled') + (this.isUnavailableDate(this.dates[i]) ? ' disabled' : ' ') + '">' +
                this.dates[i].getDate() +
                '       </div>' +
                '   </td>';
            if (cols == this.dates[i].getDay()) {
                html += '' +
                    '</tr>' +
                    '<tr>';
            }
        }
        this.domElement.innerHTML = html;

        var self = this;

        this.domElement.querySelectorAll('.day-element').forEach(function (element, index) {
            element.onclick = function () {
                self.selectDateCalendar(index, element);
            }
        });

        this.domElement.querySelectorAll('.next-month-arrow').forEach(function (element, index) {
            element.onclick = function () {
                self.nextMonth(true);
            }
        });

        this.domElement.querySelectorAll('.previous-month-arrow').forEach(function (element, index) {
            element.onclick = function () {
                self.nextMonth(false);
            }
        });
    };

    this.selectDateCalendar = function (i, el) {
        if (this.multiple) {
            if (this.selected.indexOf(formatDateForm(this.dates[i])) > -1) {
                this.selected.splice([this.selected.indexOf(formatDateForm(this.dates[i]))], 1);
                el.classList.remove('active');
            } else {
                this.selected.push(formatDateForm(this.dates[i]));
                el.classList.add('active');
            }
        } else {
            var els = this.domElement.getElementsByClassName('wrapper');
            for (var j = 0; j < els.length; j++) {
                els[j].classList.remove('active');
            }
            if (this.selected.indexOf(formatDateForm(this.dates[i])) > -1) {
                this.selected.splice([this.selected.indexOf(formatDateForm(this.dates[i]))], 1);
                el.classList.remove('active');
            } else {
                this.selected = [];
                this.selected.push(formatDateForm(this.dates[i]));
                el.classList.add('active');
            }
        }
        this.callback(formatDateForm(this.dates[i]), this.name);
    };

    this.nextMonth = function (next) {
        if (next) {
            this.contextDate.setMonth(this.contextDate.getMonth() + 1);
        } else {
            this.contextDate.setMonth(this.contextDate.getMonth() - 1);
        }
        this.setDaysCalendar();
    };
};

Calendar.counter = 0;

Calendar.create = function (id, options, callback) {
    return new Calendar().initCalendar(id, options, callback);
};

let CURRENCY_REGEX = new RegExp('R\\$\\s');

function formatMonetary(v, d) {
    let valueParsed = (typeof v == 'string' ? parseFloat(v) : v);
    return valueParsed.toLocaleString('pt-BR', {
        style: 'currency',
        currency: 'BRL',
        minimumFractionDigits: d,
        maximumFractionDigits: d,
    }).replace(CURRENCY_REGEX, '');
}
