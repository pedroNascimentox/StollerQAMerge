
(function () {
    var deliveryApp = angular.module('deliveryApp', ['ngRoute', 'sf-lookup', 'floating-button', 'infinite-scroll']);

    deliveryApp.config(function ($routeProvider) {
        $routeProvider.
        when('/opportunitylist', {
            templateUrl: window.URLS.deliveryAppOpportunityList,
            controller: 'OpportunityCtrl'
        }).
        when('/header', {
            templateUrl: window.URLS.deliveryAppHeader,
            controller: 'HeaderCtrl'
        }).
        when('/productlist', {
            templateUrl: window.URLS.deliveryAppProductList,
            controller: 'ProductCtrl'
        }).
        when('/ship', {
            templateUrl: window.URLS.deliveryAppShip,
            controller: 'ShipCtrl'
        }).
        when('/summary', {
            templateUrl: window.URLS.deliveryAppSummary,
            controller: 'SummaryCtrl'
        }).
        otherwise({
            redirectTo: '/opportunitylist'
        });
    });

    deliveryApp.controller('DeliveryCtrl', ['$scope', '$http', '$sce', '$filter', function (scope, http, $sce, $filter) {

        scope.pageView = 'insert';
        scope.oppStatus = '';
        scope.controlTime = {};
        
        scope.oppId             = oppId;
        scope.oppName           = oppName;
        scope.isCustomerService = isCustomerService;
        
        if (scope.oppId > ' ') {
            scope.pageView = 'read';
        }

        scope.isMultiple = function (p) {
            let productInCart = scope.base.selectedProducts.find(function (item) {
                return item.productId == p.productId;
            });
            return p.quantity % productInCart.multiplicity == 0;
        };

        scope.oppClass = function () {
            let css = '';
            switch (scope.pageView) {
                case 'insert':
                    css = 'oppInsert';
                    break;
                case 'edit':
                    css = 'oppEdit';
                    break;
                case 'read':
                    css = 'oppRead';
                    break;
            
                default:
                    css = 'insert';
                    break;
            }
            return css;
        }

        scope.filterProductsRecent = function (arr) {
            return arr.filter(function (item) {
                return item.recent;
            });
        };

        scope.filterProducts = function (arr) {
            return arr.filter(function (item) {
                return !item.recent;
            });
        };

        scope.filterBySearch = function (arr, val) {
            return $filter('filter')(arr, val);
        };

        scope.containerClass = '';
        scope.summaryVision = false;
        scope.step = {
            showNextStep: false,
            title: '',
            indicator: '',
            quantityStep: 5,
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
        scope.cart = {
            summaryVision: false,
            total: 0,
            header: {
                oppId: null
            },
            ship: {
                defaultDate: null,
                currentDate: '',
                dates: [],
                products: []
            },
            products: []
        };
        scope.base = {
            dolar: 4.07,
            arrOpp: [],
            arrOppFiltered: [],
            selectedOpp: null,
            currOpp: null,
            selectedProducts: [],
            selectedProductsId: [],
            selectedDeliveryId: [],
            lastIndex : []
        };
        scope.filteredPaymentConditions = [];
        scope.ship = {
            defaultDate: null,
            currentDate: '',
            dates: [],
            products: []
        };
        scope.filter = {
            billingDate: null,
            billingDateFormated: null,
            deliveryDate: null,
            deliveryDateFormated: null,
            deliveryNumber: null,
            director: null,
            open: false,
            orderNumber: null,
            regional: null,
            rtvName: null,
            selectedAccount: null,
            selectedProduct: null,
            status: null
        };
        scope.calendarVisibility = {};
        scope.default = {};

        scope.init = function () {
            callRemoteAction('DeliveryAppController.getBaseData', function (result, event) {
                console.log(result);
                if (!result.hasErrors) {
                    scope.base.confirmationDeadlineDays = result.data.confirmationDeadlineDays;
                    scope.base.cultures = result.data.cultures;
                    scope.base.orderTypes = result.data.orderTypes;
                    scope.base.deliveryQuantityLimit = result.data.deliveryQuantityLimit;
                    scope.base.unavailableDates = [];
                    result.data.holidays.forEach(function (item) {
                        let dt = formatDateForm(item.ActivityDate);
                        if (scope.base.unavailableDates.indexOf(dt) < 0) {
                            scope.base.unavailableDates.push(dt);                            
                        }
                    });
                    console.log(scope.base.unavailableDates);
                }
                scope.$apply();
            });            
        };

        scope.trustAsHtml = function (html) {
            return $sce.trustAsHtml(html);
        };

        scope.base.accountTerritories = [];

        scope.territoryFields = ['territoryName', 'name', 'rtvName'];

        scope.getTerritoryTitle = function (territory) {
            if (typeof territory != 'undefined') {
                return territory.territoryName;
            }
        };

        scope.getTerritorySubTitle = function (territory) {
            if (typeof territory != 'undefined') {
                var values = [];

                if (territory.name) {
                    values.push(territory.name.trim());
                }
                if (territory.rtvName) {
                    values.push(territory.rtvName.trim());
                }

                return values.join(' • ');
            }
        };

        scope.updateSelectedAccount = function () {

            if (scope.base.currOpp.selectedAccount == null) {
                scope.base.currOpp.receiverAccount = null;
                scope.base.currOpp.shipperAccount = null;
                scope.base.currOpp.selectedTerritory = null;
            } else {
                scope.base.accountTerritories = scope.base.currOpp.selectedAccount.territories;

                if (scope.base.accountTerritories.length == 1) {
                    scope.base.currOpp.selectedTerritory = scope.base.accountTerritories[0];
                }

                if (!scope.base.accountTerritories.length) {
                    scope.base.currOpp.selectedAccount = null;
                    Log.fire({
                        message: 'A conta não tem território associado.'
                    });
                }
            }
        };

        let accountFilters = [
            // {
            //     fieldApiName: 'Id',
            //     operator: '=',
            //     value: 'null'
            // }, 
            {
                fieldApiName: 'OpportunityId',
                operator: '=',
                value: "'" + scope.oppId + "'"
            }
        ];

        scope.filterReceiverAccount = function () {
            accountFilters.find(a => a.fieldApiName == 'OpportunityId').value = scope.base.currOpp.id;
            return accountFilters;
        };

        let receiverAccountFilters = [
            {
                fieldApiName: 'Status__c',
                operator: '!=',
                value: "\'bloqueado\'"
            }
        ];

        scope.receiverAccountFiltersFunction = function () {
            return receiverAccountFilters;
        }

        let accountReturnedFields = ['TipoCliente__c', 'RevendaAgenciadora__c', 'RatingPagamento__c', 'ShippingState', 'ShippingCity', 'NomeFazenda__c', 'ContribuinteICMS__c', 'ParentId', 'CNPJ__c'];

        scope.accountReturnedFieldsFunction = function () {
            return accountReturnedFields;
        };

        let  productReturnedFields = ['Sku__c'];
        scope.productReturnedFieldsFunction = function () {
            return productReturnedFields;
        };

        let productSearchFields = 'name;Sku__c';
        scope.productSearchFieldsFunction = function () {
            return productSearchFields;
        };

        scope.accountFields = "CNPJ__c;Name;ExternalId__c;NomeFazenda__c;ShippingCity;ShippingState;";

        scope.accountSubTitleFunction = function (fields) {
            // return accountSubTitle;
            if (typeof fields == 'undefined') {
                fields = {};
            }
            let msg = '';
            if (typeof fields.NomeFazenda__c != 'undefined') {
                msg += fields.NomeFazenda__c + ' • ';
            }
            if (typeof fields.ShippingCity != 'undefined') {
                msg += fields.ShippingCity;
            } else {
                fields.ShippingCity = '';
            }
            if (typeof fields.ShippingState != 'undefined') {
                if (fields.ShippingCity > ' ') {
                    msg += ', ';
                }
                msg += fields.ShippingState;
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
        
        scope.getProductSubtitle = function (product) {
            let msg = '';
            if (typeof product.returningFields.Sku__c != 'undefined') {
                msg += product.returningFields.Sku__c;
            }
            return msg;
        };

        scope.businessPlaceFields = 'Codigo__c;Descricao__c;';

        scope.businessPlaceReturnedFields = ['Codigo__c', 'Descricao__c'];

        scope.getBusinessPlaceTitle = function (businessPlace) {
            if (typeof businessPlace != 'undefined') {
                if (typeof businessPlace.Descricao__c != 'undefined') {
                    return businessPlace.Descricao__c;
                }
                if (typeof businessPlace.returningFields != 'undefined') {
                    return businessPlace.returningFields.Descricao__c;
                }
                return businessPlace.name;
            }
        };

        scope.getBusinessPlaceSubtitle = function (place) {
            if (typeof place != 'undefined') {
                var fields = place.returningFields || {};

                var values = [];

                if (fields.name) {
                    values.push(fields.name.trim());
                }
                if (fields.Codigo__c) {
                    values.push(fields.Codigo__c.trim());
                }

                return values.join(' • ');
            }
        };

        scope.hasAccount = function () {
            return scope.base.currOpp.selectedAccount != null
        };

    }]);

    deliveryApp.controller('OpportunityCtrl', ['$scope', '$http', function (scope, http) {

        scope.isLoading = true;

        scope.getNextRecords = function () {

            let opp =  scope.base.lastIndex;
            let last_element = opp[opp.length - 1];

            let today = last_element.createdDate.toString();
            let idDelivery = last_element.deliveryId;

            callRemoteAction('DeliveryAppController.getOpportunityListDataChunk',{
                today: today,
                idDelivery : idDelivery
                
            }, function (result, event) {
                if (event.status) {
                    if (!result.hasErrors) {
                        if(result.data.length < 1) return;
                        
                        scope.base.statusList = [];
                        scope.base.arrOpp = result.data;
                        console.log(scope.base.arrOpp);
                        let arrHelper = scope.base.arrOppFiltered;
                        //scope.base.arrOppFiltered = [];
                        scope.base.arrOpp = scope.base.arrOpp.filter(function (opp) {
                            opp.products = opp.products.filter(function (product) {
                                let checks = {
                                    billingDate: true,
                                    deliveryDate: true,
                                    orderNumber: true,
                                    deliveryNumber: true,
                                    director: true,
                                    regional: true,
                                    rtvName: true,
                                    status: true,
                                    selectedAccount: true,
                                    selectedProduct: true
                                };
                                if (scope.filter.selectedAccount != null) {
                                    checks.selectedAccount = scope.filter.selectedAccount.id == product.selectedAccount.id;
                                }
                                if (scope.filter.selectedProduct != null) {
                                    checks.selectedProduct = scope.filter.selectedProduct.id == product.productId;
                                }
                                if (scope.filter.status != null) {
                                    checks.status = scope.filter.status.label == product.status;
                                }
                                if (scope.filter.deliveryDate != null) {
                                    checks.deliveryDate = scope.filter.deliveryDate == formatDateForm(product.deliveryDate);
                                }
                                if (scope.filter.billingDate != null) {
                                    checks.billingDate = scope.filter.billingDate == formatDateForm(product.billingDate);
                                }
                                if (scope.filter.rtvName != null) {
                                    checks.rtvName = product.hasOwnProperty('rtvName') && product.rtvName.toLowerCase().indexOf(scope.filter.rtvName.toLowerCase()) > -1;
                                }
                                if (scope.filter.regional != null) {
                                    checks.regional = product.hasOwnProperty('regionalName') && product.regionalName.toLowerCase().indexOf(scope.filter.regional.toLowerCase()) > -1;
                                }
                                if (scope.filter.director != null) {
                                    checks.director = product.hasOwnProperty('directorName') && product.directorName.toLowerCase().indexOf(scope.filter.director.toLowerCase()) > -1;
                                }
                                if (scope.filter.deliveryNumber != null) {
                                    checks.deliveryNumber = product.hasOwnProperty('deliveryName') && product.deliveryName.toLowerCase().indexOf(scope.filter.deliveryNumber.toLowerCase()) > -1;
                                }
                                if (scope.filter.orderNumber != null) {
                                    checks.orderNumber = product.hasOwnProperty('oppNumber') && product.oppNumber.toLowerCase().indexOf(scope.filter.orderNumber.toLowerCase()) > -1;
                                }
                                let checkFinal = true;
                                for (const key in checks) {
                                    checkFinal = checks[key];
                                    if (!checkFinal) {
                                        break;
                                    }
                                }
                                return checkFinal;
                            });
                            return opp.products.length > 0;
                        });
                        scope.base.arrOpp.forEach(function (item) {
                            let products = [];
                            let oldOpp = arrHelper.find(a => a.key == item.key);
                            let selected = false;
                            let selectedOpp = false;
                            let emitters = [];
                            item.products.forEach(function (product) {
                                if (!scope.base.statusList.find(a => a.label == product.status)) {
                                    scope.base.statusList.push({
                                        label: product.status,
                                        value: product.status
                                    });
                                }
                                let currProd = products.find(a => a.productId == product.productId);
                                if (oldOpp) {
                                    let oldProduct = oldOpp.products.find(a => a.key == product.key);
                                    if (oldProduct) {
                                        selected = oldProduct.selected;
                                        if (selected) {
                                            selectedOpp = selected;
                                        }
                                    }
                                }
                                if (!currProd) {
                                    currProd = Object.assign({}, product);
                                    currProd.selected   = selected;
                                    currProd.receiver   = {};
                                    currProd.shipper    = {};
                                    currProd.allDates   = [];
                                    currProd.allDates.push(formatDate(product.deliveryDate));
                                    currProd.allDates.push(formatDate(item.billingDate));
                                    products.push(currProd);
                                } else {
                                    currProd.quantity += product.quantity;
                                    currProd.liter += product.liter;
                                    currProd.allDates.push(formatDate(product.deliveryDate));
                                    currProd.allDates.push(formatDate(item.billingDate));
                                }
                                if (product.receiver != null) {
                                    if (Object.keys(product.receiver).length == 0) {
                                        product.receiver = null;
                                    }
                                }
                                let currReceiver = product.receiver;
                                if (currReceiver != null) {
                                    if (Object.keys(currReceiver).length > 0) {
                                        currProd.receiver = Object.assign({}, currReceiver);
                                    }                                    
                                }
                                if (product.shipper != null) {
                                    if (Object.keys(product.shipper).length == 0) {
                                        product.shipper = null;
                                    }
                                }
                                let currShipper = product.shipper;
                                if (currShipper != null) {
                                    if (Object.keys(currShipper).length > 0) {
                                        currProd.shipper = Object.assign({}, currShipper);
                                    }                                    
                                }
                                if (emitters.indexOf(product.selectedAccount.name) < 0) {
                                    emitters.push(product.selectedAccount.name);
                                }
                                item.selectedAccountParent = Object.assign({}, product.selectedAccount);
                                product.selectedAccountParent = Object.assign({}, product.selectedAccount);
                            });
                            
                            scope.base.arrOppFiltered.push({
                                id: item.id,
                                name: item.name,
                                key: item.key,
                                selectedAccountParent: Object.assign({}, item.selectedAccount),
                                selectedAccount: item.selectedAccount,
                                emitters: emitters,
                                rtvName: item.rtvName,
                                billingDate: item.billingDate,
                                regionalName: item.regionalName,
                                directorName: item.directorName,
                                status: item.status,
                                selected: false,
                                products: products,
                                createdDate : item.createdDate,
                                deliveryId  : item.deliveryId
                            }); 
                                         
                        });

                        console.log(scope.base.arrOppFiltered);

                        scope.base.lastIndex = scope.base.arrOppFiltered;
                        
                        var unique = scope.base.arrOppFiltered
                            .map(e => e['key'])
                            .map((e, i, final) => final.indexOf(e) === i && i)
                            .filter(obj=> scope.base.arrOppFiltered[obj])
                            .map(e => scope.base.arrOppFiltered[e]);

                        scope.base.arrOppFiltered = unique;

                        console.log(scope.base.arrOppFiltered);

                        result.data = [];
                        if (scope.base.selectedOpp != null) {
                            if (!scope.base.arrOppFiltered.find(a => a.key == scope.base.selectedOpp.key)) {
                                scope.base.selectedOpp = null;
                                scope.base.selectedProducts = null;
                            }                            
                        }
                        scope.isLoading = false;
                        scope.$apply();
                    } else {
                        scope.isLoading = false;
                        scope.$apply();
                        Log.fire(result, '9834');
                    }
                } else {
                    scope.isLoading = false;
                    scope.$apply();
                    Log.fire(null, '9845');
                }
            });

        };

        scope.callRemote = function () {
            scope.isLoading = true;
            callRemoteAction('DeliveryAppController.getOpportunityListData', function (result, event) {
                scope.returnOpp(result, event);
            });
        };

        scope.returnOpp = function (result, event){
            if (event.status) {
                if (!result.hasErrors) {
                    scope.base.statusList = [];
                    scope.base.arrOpp = result.data;
                    console.log(scope.base.arrOpp);
                    let arrHelper = scope.base.arrOppFiltered;
                    scope.base.arrOppFiltered = [];
                    scope.base.arrOpp = scope.base.arrOpp.filter(function (opp) {
                        opp.products = opp.products.filter(function (product) {
                            let checks = {
                                billingDate: true,
                                deliveryDate: true,
                                orderNumber: true,
                                deliveryNumber: true,
                                director: true,
                                regional: true,
                                rtvName: true,
                                status: true,
                                selectedAccount: true,
                                selectedProduct: true
                            };
                            if (scope.filter.selectedAccount != null) {
                                checks.selectedAccount = scope.filter.selectedAccount.id == product.selectedAccount.id;
                            }
                            if (scope.filter.selectedProduct != null) {
                                checks.selectedProduct = scope.filter.selectedProduct.id == product.productId;
                            }
                            if (scope.filter.status != null) {
                                checks.status = scope.filter.status.label == product.status;
                            }
                            if (scope.filter.deliveryDate != null) {
                                checks.deliveryDate = scope.filter.deliveryDate == formatDateForm(product.deliveryDate);
                            }
                            if (scope.filter.billingDate != null) {
                                checks.billingDate = scope.filter.billingDate == formatDateForm(product.billingDate);
                            }
                            if (scope.filter.rtvName != null) {
                                checks.rtvName = product.hasOwnProperty('rtvName') && product.rtvName.toLowerCase().indexOf(scope.filter.rtvName.toLowerCase()) > -1;
                            }
                            if (scope.filter.regional != null) {
                                checks.regional = product.hasOwnProperty('regionalName') && product.regionalName.toLowerCase().indexOf(scope.filter.regional.toLowerCase()) > -1;
                            }
                            if (scope.filter.director != null) {
                                checks.director = product.hasOwnProperty('directorName') && product.directorName.toLowerCase().indexOf(scope.filter.director.toLowerCase()) > -1;
                            }
                            if (scope.filter.deliveryNumber != null) {
                                checks.deliveryNumber = product.hasOwnProperty('deliveryName') && product.deliveryName.toLowerCase().indexOf(scope.filter.deliveryNumber.toLowerCase()) > -1;
                            }
                            if (scope.filter.orderNumber != null) {
                                checks.orderNumber = product.hasOwnProperty('oppNumber') && product.oppNumber.toLowerCase().indexOf(scope.filter.orderNumber.toLowerCase()) > -1;
                            }
                            let checkFinal = true;
                            for (const key in checks) {
                                checkFinal = checks[key];
                                if (!checkFinal) {
                                    break;
                                }
                            }
                            return checkFinal;
                        });
                        return opp.products.length > 0;
                    });
                    scope.base.arrOpp.forEach(function (item) {
                        let products = [];
                        let oldOpp = arrHelper.find(a => a.key == item.key);
                        let selected = false;
                        let selectedOpp = false;
                        let emitters = [];
                        item.products.forEach(function (product) {
                            if (!scope.base.statusList.find(a => a.label == product.status)) {
                                scope.base.statusList.push({
                                    label: product.status,
                                    value: product.status
                                });
                            }
                            let currProd = products.find(a => a.productId == product.productId);
                            if (oldOpp) {
                                let oldProduct = oldOpp.products.find(a => a.key == product.key);
                                if (oldProduct) {
                                    selected = oldProduct.selected;
                                    if (selected) {
                                        selectedOpp = selected;
                                    }
                                }
                            }
                            if (!currProd) {
                                currProd = Object.assign({}, product);
                                currProd.selected = selected;
                                currProd.receiver = {};
                                currProd.shipper = {};
                                currProd.allDates = [];
                                currProd.allDates.push(formatDate(product.deliveryDate));
                                currProd.allDates.push(formatDate(item.billingDate));
                                products.push(currProd);
                            } else {
                                currProd.quantity += product.quantity;
                                currProd.liter += product.liter;
                                currProd.allDates.push(formatDate(product.deliveryDate));
                                currProd.allDates.push(formatDate(item.billingDate));
                            }
                            if (product.receiver != null) {
                                if (Object.keys(product.receiver).length == 0) {
                                    product.receiver = null;
                                }
                            }
                            let currReceiver = product.receiver;
                            if (currReceiver != null) {
                                if (Object.keys(currReceiver).length > 0) {
                                    currProd.receiver = Object.assign({}, currReceiver);
                                }
                            }
                            if (product.shipper != null) {
                                if (Object.keys(product.shipper).length == 0) {
                                    product.shipper = null;
                                }
                            }
                            let currShipper = product.shipper;
                            if (currShipper != null) {
                                if (Object.keys(currShipper).length > 0) {
                                    currProd.shipper = Object.assign({}, currShipper);
                                }
                            }
                            if (emitters.indexOf(product.selectedAccount.name) < 0) {
                                emitters.push(product.selectedAccount.name);
                            }
                            item.selectedAccountParent = Object.assign({}, product.selectedAccount);
                            product.selectedAccountParent = Object.assign({}, product.selectedAccount);
                        });
                        scope.base.arrOppFiltered.push({
                            id: item.id,
                            name: item.name,
                            key: item.key,
                            selectedAccountParent: Object.assign({}, item.selectedAccount),
                            selectedAccount: item.selectedAccount,
                            emitters: emitters,
                            rtvName: item.rtvName,
                            billingDate: item.billingDate,
                            regionalName: item.regionalName,
                            directorName: item.directorName,
                            status: item.status,
                            selected: false,
                            products: products,
                            createdDate: item.createdDate,
                            deliveryId: item.deliveryId

                        });
                    });
                    console.log(scope.base.arrOppFiltered);
                    scope.base.lastIndex = scope.base.arrOppFiltered;

                    if (scope.base.selectedOpp != null) {
                        if (!scope.base.arrOppFiltered.find(a => a.key == scope.base.selectedOpp.key)) {
                            scope.base.selectedOpp = null;
                            scope.base.selectedProducts = null;
                        }
                    }
                    scope.isLoading = false;
                    scope.$apply();
                } else {
                    scope.isLoading = false;
                    scope.$apply();
                    Log.fire(result, '9834');
                }
            } else {
                scope.isLoading = false;
                scope.$apply();
                Log.fire(null, '9845');
            }
        }

        scope.callRemote();

        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.step.title = 'Oportunidades em aberto';
        scope.step.actionNextStepText = 'Avançar';
        scope.step.indicator = 1;
        scope.step.nextTitle = 'Próximo: Detalhes da oportunidade';
        scope.step.actionNextStep = function () {
            scope.isLoading = true;
            if (scope.base.selectedOpp) {
                let opp = Object.assign({}, scope.base.arrOpp.find(a => a.key == scope.base.selectedOpp.key));
                let selectedProducts = scope.base.selectedOpp.products.filter(function (item) {
                    return item.selected;
                });
                scope.base.selectedProducts = selectedProducts;
                let selectedProductsId = [];
                selectedProducts.forEach(function (item, index) {
                    selectedProductsId.push(item.productId);
                });
                opp.products = opp.products.filter(function (item) {
                    return selectedProductsId.indexOf(item.productId) > -1;
                });
                scope.base.contextOpp = opp;
                scope.base.contextOpp.selected = false;
                scope.base.contextOpp.orderType = scope.base.orderTypes.find(function (item) {
                    return item.label == scope.base.contextOpp.orderType;
                });
                scope.base.filteredOrderTypes = scope.base.orderTypes.slice();
                let orderType = scope.base.filteredOrderTypes.find(a => a.value == 'Bonificação');
                scope.base.filteredOrderTypes.splice(scope.base.filteredOrderTypes.indexOf(orderType), 1);

                callRemoteAction('DeliveryAppController.getBaseDeliveryData', scope.base.contextOpp.id, function (result, event) {
                    if (event.status) {
                        if (!result.hasErrors) {
                            scope.base.deliveryData = result.data;
                            scope.ship.defaultDate = formatDateForm(result.data.minimumDate);
                            scope.isLoading = false;
                            scope.$apply();
                            location.href = '#/productlist';
                        } else {
                            Log.fire(result, '9784');
                        }
                    } else {
                        Log.fire(null, '9874');
                    }
                });
            }
        };
        scope.step.actionBackStep = function () {
            location.href = "/" + (scope.oppId > ' ' ? scope.oppId : 'lightning/o/Opportunity/list');
        };
        scope.step.calcCoords();
        scope.step.showNextStep = function () {
            if (scope.base.selectedOpp) {
                return true;
            }
            return false;
        };

        scope.setSelectedOpp = function () {
            scope.base.selectedOpp = scope.base.arrOppFiltered.find(a => a.selected);
        };

        scope.selectAllItems = function (oppKey) {
            let opp = scope.base.arrOppFiltered.find(a => a.key == oppKey);
            opp.products.forEach(function (item, index) {
                item.selected = opp.selected;
            });
            scope.setSelectedOpp();
        };

        scope.validateSelectedOpp = function (oppKey) {
            let opp = scope.base.arrOppFiltered.find(a => a.key == oppKey);
            let haveSelected = false;
            opp.products.forEach(function (item, index) {
                if (item.selected) {
                    haveSelected = true;
                    return false;
                }
            });
            opp.selected = haveSelected;
            scope.setSelectedOpp();
        };

        scope.isSelectedOpp = function (oppKey) {
            return (scope.base.selectedOpp != null ? scope.base.selectedOpp.key == oppKey ? '' : 'disabled' : '');
        }

        scope.termSearch;

        scope.clearSearch = function () {
            scope.termSearch = null;
            document.getElementById('txtTermSearch').focus();
        };

        scope.formatPrice = function (price) {
            return formatMonetary(price, 2);
        };

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

        scope.setCalendarDeliveryDate = function (dt, name) {
            scope.filter.deliveryDate = dt;
            scope.filter.deliveryDateFormated = formatDate(dt);
            scope.openCalendar(name);
            scope.$apply();
        };
        
        scope.setCalendarBillingDate = function (dt, name) {
            scope.filter.billingDate = dt;
            scope.filter.billingDateFormated = formatDate(dt);
            scope.openCalendar(name);
            scope.$apply();
        };

        scope.openCalendar = function (name) {
            scope.calendarVisibility[name] = !scope.calendarVisibility[name];
        };

        calendarDeliveryDate = Calendar.create('wrapper-delivery-date', {
            dates: {},
            initDate: formatDateForm(new Date()),
            isOpen: true,
            name: 'delivery-date',
            greaterThanInit: false,
            lessThanInit: false,
            weekendAvaliable: true
        }, function (result, name) {
            scope.setCalendarDeliveryDate(result, name);
        });

        scope.calendarVisibility[calendarDeliveryDate.name] = false;
        
        calendarBillingDate = Calendar.create('wrapper-billing-date', {
            dates: {},
            initDate: formatDateForm(new Date()),
            isOpen: true,
            name: 'billing-date',
            greaterThanInit: false,
            lessThanInit: false,
            weekendAvaliable: true
        }, function (result, name) {
            scope.setCalendarBillingDate(result, name);
        });

        scope.calendarVisibility[calendarBillingDate.name] = false;

        scope.clearDeliveryDate = function () {
            scope.filter.deliveryDate = null;
            scope.filter.deliveryDateFormated = null;
        };

        scope.clearBillingDate = function () {
            scope.filter.billingDate = null;
            scope.filter.billingDateFormated = null;
        };

        scope.advancedFilterOpp = function () {
            scope.filter.open = false;
            scope.callRemote();
        };

        scope.searchOpp = function(){
            var numOpp = $('#txtTermSearch').val();
            console.log(numOpp);
            scope.isLoading = true;
            if (numOpp){
                callRemoteAction('DeliveryAppController.getOpportunityListDataOpp', '%'+numOpp+'%',function (result, event) {
                    scope.returnOpp(result, event);
                    scope.isLoading = false;
                });
            } else {
                callRemoteAction('DeliveryAppController.getOpportunityListData', function (result, event) {
                    scope.returnOpp(result, event);
                    scope.isLoading = false;
                });
            }
        }

        scope.openAdvancedSearch = function (open) {
            scope.filter.open = open;
            if (!open) {
                scope.filter = {
                    billingDate: null,
                    billingDateFormated: null,
                    deliveryDate: null,
                    deliveryDateFormated: null,
                    deliveryNumber: null,
                    director: null,
                    open: false,
                    orderNumber: null,
                    regional: null,
                    rtvName: null,
                    selectedAccount: null,
                    selectedProduct: null,
                    status: null
                };
                scope.callRemote();
            }
        };

    }]);

    deliveryApp.controller('ProductCtrl', ['$scope', '$http', function (scope, $http) {

        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.step.title = 'Detalhes da ' + scope.base.contextOpp.name;
        scope.step.actionNextStepText = 'Avançar';
        scope.step.indicator = 2;
        scope.step.nextTitle = 'Próximo: Alterações de envio';
        scope.step.calcCoords();
        scope.step.actionNextStep = function () {
            scope.default.deliveryDate = null;
            scope.default.deliveryDateFormated = null;
            scope.base.currOpp = Object.assign({}, scope.base.contextOpp);
            scope.base.currOpp.products = JSON.parse(JSON.stringify(scope.base.contextOpp.products.slice()));
            scope.base.currOpp.products = scope.base.currOpp.products.filter(function (item) {
                return item.selected;
            });
            scope.ship.currentDate = null;
            let selectedDeliveryId = [];
            scope.base.currOpp.products.forEach(function (item, index) {
                selectedDeliveryId.push(item.id);
            });
            scope.base.selectedDeliveryId = selectedDeliveryId;
            let balances    = {};
            let emitters    = {};
            let territories = {};
            let business    = {};
            let shippers    = {};
            let receivers   = {};
            let orderTypes  = [];
            scope.base.currOpp.products.forEach(function (item, index) {

                if (!emitters.hasOwnProperty(item.selectedAccount.id)) {
                    emitters[item.selectedAccount.id] = item.selectedAccount;
                }
                if (item.territoryData) {
                    if (!territories.hasOwnProperty(item.territoryData.territory)) {
                        territories[item.territoryData.territory] = item.territoryData;
                    }                    
                }
                if (item.shipper) {
                    if (!shippers.hasOwnProperty(item.shipper.id)) {
                        shippers[item.shipper.id] = item.shipper;
                    }                    
                }
                if (item.businessPlace) {
                    if (!business.hasOwnProperty(item.businessPlace.id)) {
                        business[item.businessPlace.id] = item.businessPlace;
                    }                    
                }
                if (item.receiver) {
                    if (!receivers.hasOwnProperty(item.receiver.id)) {
                        receivers[item.receiver.id] = item.receiver;
                    }                    
                }
                if (orderTypes.indexOf(item.orderType) < 0) {
                    orderTypes.push(item.orderType);
                }

                if (!balances.hasOwnProperty(item.productId)) {
                    balances[item.productId] = 0;
                }
                balances[item.productId] += item.quantity;
                let dt = item.deliveryDate = formatDateForm(item.deliveryDate);
                if (scope.ship.currentDate == null || scope.ship.currentDate > dt) {
                    scope.ship.currentDate = dt;
                }
                if (scope.ship.dates.indexOf(dt) < 0) {
                    scope.ship.dates.push(dt);
                }

            });
            for (const key in balances) {
                (scope.base.selectedProducts.find(a => a.productId == key) || {}).quantity = balances[key];
            }

            if (orderTypes.length > 1) {
                scope.base.currOpp.orderType = null;
            }else {
                scope.base.currOpp.orderType = scope.base.orderTypes.find(function (item) {
                    return item.label == orderTypes[0];
                });
            }
            if (Object.keys(emitters).length > 1) {
                scope.base.currOpp.selectedAccount          = null;
                scope.base.currOpp.selectedAccountParent    = null;
            }else {
                for (const key in emitters) {
                    scope.base.currOpp.selectedAccount          = emitters[key];
                    scope.base.currOpp.selectedAccountParent    = emitters[key];
                }
                scope.base.accountTerritories           = scope.base.currOpp.selectedAccount.territories;
                scope.base.currOpp.selectedTerritory    = scope.base.currOpp.territoryData;
                if (scope.base.accountTerritories.length == 1 && !scope.base.currOpp.selectedTerritory) {
                    scope.base.currOpp.selectedTerritory = scope.base.accountTerritories[0];
                }
            }
            if (Object.keys(territories).length > 1) {
                scope.base.currOpp.selectedTerritory = null;
            } else {
                for (const key in territories) {
                    scope.base.currOpp.selectedTerritory = territories[key];
                }
            }
            
            if (Object.keys(shippers).length > 1) {
                scope.base.currOpp.shipper = null;
            }else {
                for (const key in shippers) {
                    scope.base.currOpp.shipper = shippers[key];
                }
            }
            if (Object.keys(receivers).length > 1) {
                scope.base.currOpp.receiver = null;
            }else {
                for (const key in receivers) {
                    scope.base.currOpp.receiver = receivers[key];
                }
            }
            if (Object.keys(business).length > 1) {
                scope.base.currOpp.selectedBusinessPlace = null;
            } else {
                for (const key in business) {
                    scope.base.currOpp.selectedBusinessPlace = business[key];
                }
            }
            
            location.href = "#/header";
        };
        scope.step.actionBackStep = function () {
            if (scope.base.currOpp != null) {
                scope.base.currOpp.products = [];                
            }
            scope.base.selectedOpp = null;
            scope.base.selectedProducts = null;
            scope.base.arrOpp = [];
            scope.base.arrOppFiltered = [];
            location.href = "#/opportunitylist";
        };
        scope.step.showNextStep = function () {
            return scope.base.contextOpp.selected;
        };

        scope.selectAllItems = function () {
            scope.base.contextOpp.products.forEach(function (item) {
                item.selected = scope.base.contextOpp.selected;
            });
        };

        scope.validateSelectedOpp = function () {
            let haveSelected = false;
            scope.base.contextOpp.products.forEach(function (item) {
                if (item.selected) {
                    haveSelected = true;
                    return false;
                }
            });
            scope.base.contextOpp.selected = haveSelected;
        };

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

    }]);
    
    deliveryApp.controller('HeaderCtrl', ['$scope', '$http', function (scope, $http) {

        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.step.title = 'Alterações de envio';
        scope.step.actionNextStepText = 'Avançar';
        scope.step.indicator = 3;
        scope.step.nextTitle = 'Próximo: Datas de Entrega';
        scope.step.calcCoords();
        scope.setDeliveryProducts = function () {
            let arrProducts = [];
            scope.base.currOpp.products.forEach(function (item) {
                if (scope.base.currOpp.receiver != null) {
                    item.receiver = scope.base.currOpp.receiver;
                }
            });
            scope.base.currOpp.products.forEach(function (product, index) {
                let currentProduct = arrProducts.find(function (item) {
                    product.billingDate = formatDateForm(getBusinessDate(product.deliveryDate, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false));
                    let checkReceiver = true;
                    if (scope.base.currOpp.orderType.value == 'Conta e Ordem') {
                        let receiverItem = item.receiver;
                        let receiverProduct = product.receiver;
                        if (receiverItem == null) {
                            receiverItem = {
                                id: ''
                            };
                        }
                        if (Object.keys(receiverItem).length == 0) {
                            receiverItem = {
                                id: ''
                            };
                        }
                        if (receiverProduct == null) {
                            receiverProduct = {
                                id: ''
                            };
                        }
                        if (Object.keys(receiverProduct).length == 0) {
                            receiverProduct = {
                                id: ''
                            };
                        }
                        checkReceiver = receiverProduct.id == receiverItem.id;
                    }
                    return product.productId == (item || {}).productId && product.deliveryDate == (item || {}).deliveryDate && checkReceiver;
                });
                if (!currentProduct) {
                    arrProducts.push(product);
                } else {
                    currentProduct.quantity += product.quantity;
                }
            });
            scope.base.currOpp.products = arrProducts;
            scope.base.currOpp.products.forEach(function (item, index) {
                let dt = item.deliveryDate = formatDateForm(item.deliveryDate);
                if (scope.ship.currentDate == null || scope.ship.currentDate > dt) {
                    scope.ship.currentDate = dt;
                }
                if (scope.ship.dates.indexOf(dt) < 0) {
                    scope.ship.dates.push(dt);
                }
            });
            location.href = "#/ship";
        };
        scope.step.actionNextStep = function () {
            scope.ship.currentDate = null;
            debugger;
            if (scope.isCustomerService) {
                callRemoteAction('DeliveryAppController.getDeliveryData', {
                    emitterId: scope.base.currOpp.selectedAccount.id,
                    receiverId: (scope.base.currOpp.receiverAccount != null ? scope.base.currOpp.receiverAccount.id : null),
                    businessPlaceId: scope.base.currOpp.selectedBusinessPlace.id,
                    expeditionCondition: scope.base.currOpp.products[0].expeditionCondition
                }, function (result, event) {
                    if (event.status) {
                        if (!result.hasErrors) {
                            scope.base.deliveryData = result.data;
                            scope.ship.defaultDate = formatDateForm(result.data.minimumDate);
                            scope.isLoading = false;
                            scope.setDeliveryProducts();
                            scope.$apply();
                        } else {
                            Log.fire(result, '9284');
                        }
                    } else {
                        Log.fire(null, '9174');
                    }
                });
            }else {
                scope.setDeliveryProducts();
            }            
        };
        scope.step.actionBackStep = function () {
            Swal.fire({
                title: 'Descartar?',
                html: 'Se você voltar para tela anterior, todas alterações realizadas até agora serão descartadas!',
                type: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#3085d6',
                confirmButtonText: 'Descartar!',
                cancelButtonText: 'Nãoooo'
            }).then((result) => {
                if (result.value) {
                    scope.base.currOpp.products = [];
                    location.href = "#/productlist";
                }
            });
        };
        scope.step.showNextStep = function () {
            let shipper = true;
            if (scope.base.currOpp.orderType) {
                if (scope.base.currOpp.orderType.value == 'Remanejamento') {
                    if (!scope.base.currOpp.shipper) {
                        shipper = false;
                    }
                }                
            }
            let territory = true;
            if (scope.isCustomerService) {
                if (!scope.base.currOpp.selectedTerritory) {
                    territory = false;
                }
            }
            return scope.base.currOpp.selectedAccount != null && scope.base.currOpp.orderType != null && shipper && territory;
        };

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

        scope.setDefaultDeliveryDate = function () {
            let dt = scope.default.deliveryDate;
            scope.base.currOpp.products.forEach(function (item) {
                item.deliveryDate   = dt;
                item.billingDate    = formatDateForm(getBusinessDate(dt, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false))
            });
        };

        scope.setCalendarDeliveryDate = function (dt, name) {
            scope.default.deliveryDate = dt;
            scope.default.deliveryDateFormated = formatDate(dt);
            scope.openCalendar(name);
            scope.$apply();
        };
        scope.openCalendar = function (name) {
            scope.calendarVisibility[name] = !scope.calendarVisibility[name];
        };
        calendarDeliveryDate = Calendar.create('wrapper-delivery-date', {
            dates: {},
            name: 'delivery-date',
            initDate: scope.ship.defaultDate,
            isOpen: true,
            greaterThanInit: true,
            weekendAvaliable: false,
            unavailableDates: scope.base.unavailableDates
        }, function (result, name) {
            scope.setCalendarDeliveryDate(result, name);
        });

        scope.calendarVisibility[calendarDeliveryDate.name] = false;

    }]);

    deliveryApp.controller('ShipCtrl', ['$scope', '$http', function (scope, http) {
        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.step.title = 'Datas de Entrega';
        scope.step.actionNextStepText = 'Avançar';
        scope.step.indicator = 3;
        scope.step.nextTitle = 'Próximo: Resumo e confirmação';
        scope.step.calcCoords();
        scope.step.actionNextStep = function () {
            location.href = "#/summary";
        };
        scope.step.actionBackStep = function () {
            location.href = "#/header";
        };
        debugger;
        scope.validateConfirmedItem = function (item) {
            debugger;
            if ((scope.base.selectedOpp.selectedAccount.type == 'ZE' && item.type == 'Defensivo' && item.confirmed) && (item.registrationNumber <= '' || item.guide <= '')) {
                Swal.fire({
                    type: 'warning',
                    title: 'Atenção',
                    html: 'Produto defensivo para Consumidor Final. Necessário inserir RA e Guia para confirmar a entrega'
                });
                item.confirmed = false;
            }
            
        }

        scope.uncheckRAandGuide = function (item) {
            if(item.registrationNumber <= '' || item.guide <= ''){
                item.confirmed = false;
            }
        }


        scope.showNumberOfDeliveriesAlert = function () {
            return (!isCustomerService && scope.base.currOpp.ovNumbers > 0);
        }

        scope.generateAlertMessage = function () {
            
            var foundOpp = scope.base.arrOpp.find(a => a.key == scope.base.currOpp.key);
            var deliveryQuantityLimit = scope.base.deliveryQuantityLimit < foundOpp.products.length ? foundOpp.products.length : scope.base.deliveryQuantityLimit;
            
            var deliveryLimitCalc = deliveryQuantityLimit - scope.base.currOpp.ovNumbers;
            
            var message;

            if ((deliveryLimitCalc) == 1){
                message = "Você só pode criar " + deliveryLimitCalc + " ordem de venda. Programe todas as suas entregas!";
            } else {
                message = "Você ainda pode criar " + deliveryLimitCalc + " ordens de venda. Programe suas entregas.";
            }

            return message;
        }

        scope.haveInvalidDate = function () {
            var invalidDates = scope.ship.dates.filter(function (item) {
                return item < scope.ship.defaultDate;
            });
            return invalidDates;
        };

        scope.step.showNextStep = function () {
            let oppProducts = scope.base.selectedProducts;
            let multiplicityOk = true;
            scope.cart.products.forEach(function (item, index) {
                if (item.quantity % item.multiplicity > 0) {
                    multiplicityOk = false;
                }
            });
            oppProducts = oppProducts.filter(function (item) {
                return scope.base.currOpp.products.find(a => a.productId == item.productId);
            });
            var allBalance = oppProducts.reduce(function (sum, num) {
                return sum + num.balance
            }, 0);
            var itemsConfirmedWhithoutReceiver = [];
            if (scope.base.currOpp.orderType.value == 'Conta e Ordem') {
                itemsConfirmedWhithoutReceiver = scope.base.currOpp.products.filter(function (item) {
                    return (item.confirmed && item.receiver == null);
                });
            }

            /*
            var rtvDeliveryLimitValid = false;
            var foundOpp = scope.base.arrOpp.find(a => a.key == scope.base.selectedOpp.key);
            var deliveryQuantityLimit = scope.base.deliveryQuantityLimit < foundOpp.products.length ? foundOpp.products.length : scope.base.deliveryQuantityLimit;
            if (!isCustomerService){
                rtvDeliveryLimitValid = (deliveryQuantityLimit - scope.base.currOpp.ovNumbers) >= scope.ship.dates.length ? true : false;
            } else {
                rtvDeliveryLimitValid = true;
            }
            */
            
            return (allBalance == 0 && itemsConfirmedWhithoutReceiver.length == 0 && scope.haveInvalidDate().length == 0 && multiplicityOk); //&& rtvDeliveryLimitValid);
        };

        scope.showCalendar = false;
        scope.showMoreDates = true;

        scope.isValidDate = function (item) {
            item.billingDate = formatDateForm(getBusinessDate(item.deliveryDate, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false));
            let confirmationDeadlineDate    = new Date(item.billingDate);
            confirmationDeadlineDate.setDate(confirmationDeadlineDate.getDate() - scope.base.confirmationDeadlineDays);
            if (isEqualOrGreaterThan(item.deliveryDate, scope.ship.defaultDate) && isDateInRange(new Date(), confirmationDeadlineDate, item.billingDate)) {
                return true;
            }
            item.confirmed = false;
            return false;
        };

        scope.isBlockedAcc = function (item) {
            return item.orderType == 'Bonificação' ? true : !(item.selectedAccount ? item.selectedAccount.block : item.receiver.block);
        };

        scope.isValidAcc = function (item) {
            return !(item.selectedAccount ? item.selectedAccount.block : item.receiver.block);
        };

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };
        scope.isEqualOrGreaterThanScope = function (d1, d2) {
            return isEqualOrGreaterThan(d1, d2);
        };
        scope.currentDate = scope.ship.currentDate;
        if (!scope.currentDate) {
            if (scope.ship.dates.length > 0) {
                scope.currentDate = scope.ship.dates[0].date;
            } else {
                scope.currentDate = scope.ship.defaultDate;
                scope.ship.dates.push(scope.currentDate);
            }
        }
        scope.oldDate = scope.currentDate;
        scope.validateShowMoreDate = function () {
            if (scope.ship.dates.indexOf(scope.currentDate) < 0) {
                if (scope.ship.dates.length > 0) {
                    scope.currentDate = scope.ship.dates[0];
                } else {
                    scope.currentDate = scope.ship.defaultDate;
                }
            }
            let oppProducts = scope.base.selectedProducts;
            oppProducts = oppProducts.filter(function (item) {
                return scope.base.currOpp.products.find(a => a.productId == item.productId);
            });
            var allBalance = oppProducts.reduce(function (sum, num) {
                if (num.hasOwnProperty('balance')) {
                    return sum + num.balance;
                }
                return sum + 0;
            }, 0);
            if (allBalance <= 0) {
                scope.showMoreDates = false;
                return false;
            }

            scope.showMoreDates = true;

            if (scope.createNewDate){

                var foundOpp = scope.base.arrOpp.find(a => a.key == scope.base.selectedOpp.key);

                var filterdSelectedOppProducts = foundOpp.products.filter(function (item){
                    return scope.base.selectedDeliveryId.indexOf(item.id) < 0;
                });

                var allDates    = [];
                var allDatesMap = {};

                filterdSelectedOppProducts.forEach(function (item) {
                    if(allDates.indexOf(formatDateForm(item.deliveryDate)) < 0){
                        allDates.push(formatDateForm(item.deliveryDate));
                        allDatesMap[formatDateForm(item.deliveryDate)] = null;
                    }
                })

                scope.ship.dates.forEach(function (item) {
                    if (allDates.indexOf(formatDateForm(item)) < 0) {
                        allDates.push(formatDateForm(item));
                        allDatesMap[formatDateForm(item)] = null;
                    }
                })

                debugger;

                var deliveryQuantityLimit = scope.base.deliveryQuantityLimit < foundOpp.products.length ? foundOpp.products.length : scope.base.deliveryQuantityLimit;

                if (!scope.isCustomerService && allDates.length >= deliveryQuantityLimit) {
                    initCalendar('wrapper-calendar', {
                        dates: allDatesMap,
                        initDate: scope.ship.defaultDate,
                        weekendAvaliable: false,
                        unavailableDates: scope.base.unavailableDates
                    }, function (result) {
                        scope.setDate(result);
                    });
                    //scope.showMoreDates = false;
                } else {
                    initCalendar('wrapper-calendar', {
                        dates: {},
                        initDate: scope.ship.defaultDate,
                        isOpen: true,
                        greaterThanInit: true,
                        weekendAvaliable: false,
                        unavailableDates: scope.base.unavailableDates
                    }, function (result) {
                        scope.setDate(result);
                    });
                    //scope.showMoreDates = true;
                }
            }
        };

        scope.inspectorShip = function () {
            let arrHelper = [];
            scope.base.currOpp.products.forEach(function (item, index) {
                let push = true;
                let productInCart = scope.base.selectedProducts.find(function (product) {
                    return product.productId == item.productId;
                });
                if (typeof productInCart != 'undefined') {
                    if (item.quantity == 0 && productInCart.balance <= 0) {
                        push = false;
                        delete productInCart.balance;
                    }
                }else {
                    push = false;
                }
                if (push) {
                    arrHelper.push(item);
                }
            });
            scope.base.currOpp.products = arrHelper;
            arrHelper = [];
            scope.ship.dates.forEach(function (item, index) {
                let product = scope.base.currOpp.products.find(function (p) {
                    p.deliveryDate = formatDateForm(p.deliveryDate);
                    return p.deliveryDate == item;
                });
                if (typeof product != 'undefined' && arrHelper.indexOf(item) < 0) {
                    arrHelper.push(item);
                }
            });
            scope.ship.dates = arrHelper;
            scope.validateShowMoreDate();
        };

        scope.prepareDate = function (dt, cut) {
            scope.ship.currentDate = scope.currentDate = dt;
            if (scope.ship.dates.indexOf(dt) < 0) {
                scope.ship.dates.push(dt);
            }
            var productsInAllDates = scope.base.currOpp.products.filter(function (product) {
                return scope.base.selectedProducts.find(function (item) {
                    return product.productId == item.productId;
                });
            });
            var productsDate = productsInAllDates.filter(function (item) {
                return item.deliveryDate == dt;
            });
            if (cut) {
                var productsOldDate = productsInAllDates.filter(function (item) {
                    return item.deliveryDate == scope.oldDate;
                });
                productsOldDate.forEach(function (product, productIndex) {
                    let currentProduct = productsDate.find(function (item) {
                        let receiverItem = item.receiver;
                        let receiverProduct = product.receiver;
                        if (receiverItem == null) {
                            receiverItem = {
                                id: ''
                            };
                        }
                        if (Object.keys(receiverItem).length == 0) {
                            receiverItem = {
                                id: ''
                            };
                        }
                        if (receiverProduct == null) {
                            receiverProduct = {
                                id: ''
                            };
                        }
                        if (Object.keys(receiverProduct).length == 0) {
                            receiverProduct = {
                                id: ''
                            };
                        }
                        return (
                            product.productId == item.productId &&
                            receiverProduct.id == receiverItem.id
                        );
                    });
                    if (!currentProduct) {
                        product.deliveryDate    = dt;
                        product.billingDate     = formatDateForm(getBusinessDate(dt, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false));
                    } else {
                        let qtd = product.quantity;
                        currentProduct.quantity += qtd;
                        product.quantity -= qtd;
                    }
                });
            } else {
                let oppProducts = scope.base.selectedProducts;
                oppProducts = oppProducts.filter(function (item) {
                    return scope.base.currOpp.products.find(a => a.productId == item.productId);
                });
                oppProducts.forEach(function (product, index) {
                    let currentProduct = productsDate.find(function (item) {
                        let receiverItem = item.receiver;
                        let receiverProduct = product.receiver;
                        if (receiverItem == null) {
                            receiverItem = {
                                id: ''
                            };
                        }
                        if (Object.keys(receiverItem).length == 0) {
                            receiverItem = {
                                id: ''
                            };
                        }
                        if (receiverProduct == null) {
                            receiverProduct = {
                                id: ''
                            };
                        }
                        if (Object.keys(receiverProduct).length == 0) {
                            receiverProduct = {
                                id: ''
                            };
                        }
                        return (
                            product.productId == item.productId &&
                            receiverProduct.id == receiverItem.id
                        );
                    });
                    if (!currentProduct) {
                        let productArrayHelper = scope.base.contextOpp.products.filter(function (item) {
                            return item.selected;
                        });
                        let producthelper = productArrayHelper.find(a => a.productId == product.productId); 
                        debugger;
                        if (product.quantity > 0 && product.balance > 0) {
                            currentProduct = {
                                registrationNumber: product.registrationNumber,
                                guide: product.guide,
                                type: product.type,
                                id: producthelper.id,
                                productId: product.productId,
                                itemId: producthelper.itemId,
                                billingDate: formatDateForm(getBusinessDate(dt, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false)),
                                name: product.name,
                                orderNumber: '',
                                sku: product.sku,
                                deliveryDate: dt,
                                quantity: product.balance,
                                receiver: scope.base.currOpp.receiver,
                                confirmedDate: null,
                                confirmed: false,
                                baseLiter: product.baseLiter,
                                selectedAccount: product.selectedAccount,
                                orderType: product.orderType
                            };
                            product.balance = 0;
                            scope.base.currOpp.products.unshift(currentProduct);
                        }
                    }
                });
            }
            scope.showCalendar = false;
            scope.inspectorShip();
        };

        scope.resolveInvalidDate = function () {
            var invalidDates = scope.haveInvalidDate();
            invalidDates.forEach(function (item) {
                scope.oldDate = item;
                scope.prepareDate(scope.ship.defaultDate, true);
            });
            Toast.fire({
                type: 'success',
                title: 'Show! Datas inválidas resolvidas'
            });
            scope.$apply();
        };

        scope.resolveInvalidDatePopUp = function () {
            var invalidDates = scope.haveInvalidDate();
            Swal.fire({
                title: (invalidDates.length > 1 ? 'Datas inválidas?' : 'Data inválida?'),
                html: 'Ao clicar em resolver, todas as programações inválidas serão realocadas para a data mínima (' + formatDate(scope.ship.defaultDate) + ')<br/>' +
                    '<div class="collapsible left">' +
                    '   <input type="checkbox" id="resolveDates" />' +
                    '   <div class="collapsible-header">' +
                    '       <label for="resolveDates">' +
                    '           <svg class="slds-button__icon collapsible-down" aria-hidden="true">' +
                    '               <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevrondown"></use>' +
                    '           </svg>' +
                    '           <svg class="slds-button__icon collapsible-up" aria-hidden="true">' +
                    '               <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevronup"></use>' +
                    '           </svg>' +
                    '           <small>Como resolver manualmente?</small>' +
                    '       </label>' +
                    '   </div>' +
                    '   <div class="collapsible-body">' +
                    '       <p class="p-info">Ao clicar em cima de uma data inválida, abrirá um calendário para selecionar uma nova data válida.</p>' +
                    '       <p class="p-info">Assim, todas as programações da data inválida serão realocadas na data válida selecionada!</p>' +
                    '   </div>' +
                    '</div>',
                type: 'info',
                showCancelButton: true,
                confirmButtonColor: '#3085d6',
                confirmButtonText: 'Resolver!',
                cancelButtonText: 'Nãoooo'
            }).then((result) => {
                if (result.value) {
                    scope.resolveInvalidDate();
                }
            });
        };

        scope.calcBalance = function (p) {
            let productInCart = scope.base.selectedProducts.find(function (item) {
                return item.productId == p.productId;
            });
            let arr = scope.base.currOpp.products.filter(function (item) {
                return item.productId == p.productId;
            });

            let allQuantity = arr.reduce(function (sum, num) {
                return sum + num.quantity;
            }, 0);
            if (allQuantity > productInCart.quantity) {
                let newBalance = productInCart.quantity;
                for (let index = (scope.base.currOpp.products.length - 1); index >= 0; index--) {
                    const product = scope.base.currOpp.products[index];
                    if (product.productId == productInCart.productId) {
                        if (newBalance > 0) {
                            if (product.quantity <= newBalance) {
                                newBalance -= product.quantity;
                            } else {
                                scope.base.currOpp.products[index].quantity = newBalance;
                            }
                        } else {
                            scope.base.currOpp.products.splice(index, 1);
                        }
                    }
                }
                scope.calcBalance(p);
                return false;
            }

            var preBalance = productInCart.quantity - allQuantity;
            if (preBalance < 0) {
                p.quantity += preBalance;
                allQuantity += preBalance;
                preBalance = productInCart.quantity - allQuantity;
            }
            productInCart.balance = preBalance;
            scope.inspectorShip();
            return productInCart.balance;
        };

        scope.init = function () {
            scope.base.selectedProducts.forEach(function (item, index) {
                if (!item.hasOwnProperty('balance') && item.quantity > 0) {
                    item.balance = item.quantity;
                }
            });
            if (scope.pageView != 'read') {
                scope.prepareDate(scope.currentDate, false);
            }
            initCalendar('wrapper-calendar', {
                dates: {},
                initDate: scope.ship.defaultDate,
                isOpen: true,
                greaterThanInit: true,
                weekendAvaliable: false,
                unavailableDates: scope.base.unavailableDates
            }, function (result) {
                scope.setDate(result);
            });
        };

        scope.init();

        scope.setNewReceiver = function (product) {
            let productInCart = scope.base.selectedProducts.find(function (item) {
                return item.productId == product.productId;
            });
            let currentProduct = {
                id: product.id,
                productId: product.productId,
                itemId: product.itemId,
                billingDate: formatDateForm(getBusinessDate(scope.currentDate, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false)),
                name: product.name,
                orderNumber: '',
                sku: product.sku,
                deliveryDate: scope.currentDate,
                quantity: productInCart.balance,
                receiver: null,
                confirmedDate: null,
                confirmed: false,
                baseLiter: product.baseLiter
            };
            productInCart.balance   = 0;
            scope.base.currOpp.products.unshift(currentProduct);
        };

        scope.showNewReceiver = function (p) {
            let productInCart = scope.base.selectedProducts.find(function (item) {
                return item.productId == p.productId;
            });
            let arr = scope.base.currOpp.products.filter(function (item) {
                return item.productId == p.productId;
            });
            let haveItemWithoutReceiver = arr.filter(function (item) {
                return item.receiver == null && item.deliveryDate == scope.currentDate;
            });
            let confirm = false;
            if (scope.base.currOpp.orderType) {
                if (scope.base.currOpp.orderType.value == 'Conta e Ordem') {
                    confirm = true;
                    if (haveItemWithoutReceiver.length > 0) {
                        confirm = false;                        
                    }
                }
            }
            return productInCart.balance > 0 && confirm;
        }

        scope.setDate = function (dt) {
            let cut = (scope.oldDate > ' ');
            scope.oldDate = scope.currentDate;
            calendar.selected = [];
            scope.prepareDate(dt, cut);
            scope.$apply();
        };

        scope.openCalendar = function () {
            scope.createNewDate = true;
            if (scope.oldDate == '') {
                scope.showCalendar = !scope.showCalendar;
            } else {
                scope.showCalendar = true;
                scope.oldDate = '';
            }
            calendar.selected = [];
        };

        scope.openSelectedDate = function (dt) {

            scope.createNewDate = false;
            scope.oldDate       = dt;

            debugger;

            var foundOpp = scope.base.arrOpp.find(a => a.key == scope.base.selectedOpp.key);

            var filterdSelectedOppProducts = foundOpp.products.filter(function (item) {
                return scope.base.selectedDeliveryId.indexOf(item.id) < 0;
            });

            var allDates = [];
            var allDatesMap = {};
            var filterdSelectedOppProductsDates = [];

            filterdSelectedOppProducts.forEach(function (item) {
                if (allDates.indexOf(formatDateForm(item.deliveryDate)) < 0) {
                    allDates.push(formatDateForm(item.deliveryDate));
                    filterdSelectedOppProductsDates.push(formatDateForm(item.deliveryDate));
                    allDatesMap[formatDateForm(item.deliveryDate)] = null;
                }
            })

            scope.ship.dates.forEach(function (item) {
                if (allDates.indexOf(formatDateForm(item)) < 0) {
                    allDates.push(formatDateForm(item));
                    allDatesMap[formatDateForm(item)] = null;
                }
            })

            debugger;

            var newSelectedDate = filterdSelectedOppProductsDates.indexOf(dt) < 0;

            scope.showMoreDates = true;

            var deliveryQuantityLimit = scope.base.deliveryQuantityLimit < foundOpp.products.length ? foundOpp.products.length : scope.base.deliveryQuantityLimit;

            if (!scope.isCustomerService && allDates.length >= deliveryQuantityLimit && !newSelectedDate) {
                initCalendar('wrapper-calendar', {
                    dates: allDatesMap,
                    initDate: scope.ship.defaultDate,
                    weekendAvaliable: false,
                    unavailableDates: scope.base.unavailableDates
                }, function (result) {
                    scope.setDate(result);
                });
                //scope.showMoreDates = false;
            } else {
                initCalendar('wrapper-calendar', {
                    dates: {},
                    initDate: scope.ship.defaultDate,
                    isOpen: true,
                    greaterThanInit: true,
                    weekendAvaliable: false,
                    unavailableDates: scope.base.unavailableDates
                }, function (result) {
                    scope.setDate(result);
                });
                //scope.showMoreDates = true;
            }

            
            if (scope.currentDate == dt) {
                if (scope.pageView == 'read') {
                    return false;
                }
                scope.showCalendar = !scope.showCalendar;
            } else {
                scope.currentDate = dt;
                scope.showCalendar = false;
            }
            calendar.selected = [dt];
        };
        scope.increment = function (p) {
            scope.quantityChange(p, true, true);
        };

        scope.decrement = function (p) {
            scope.quantityChange(p, true, false);
        };

        scope.quantityChange = function (p, helper, plus) {
            if (!p.quantity) {
                p.quantity = 0
            }
            if (scope.controlTime.hasOwnProperty(p.id)) {
                clearTimeout(scope.controlTime[p.id]);
            }
            let productInCart = scope.base.selectedProducts.find(function (item) {
                return item.productId == p.productId;
            });
            if (p.quantity > productInCart.quantity) {
                p.quantity = productInCart.quantity;
            }
            var newQuantityDate = p.quantity;
            if (helper) {
                let value = (productInCart.multiplicity > 0 ? productInCart.multiplicity : 1);
                if (plus) {
                    newQuantityDate += (productInCart.balance > value ? value : productInCart.balance);
                } else {
                    newQuantityDate -= value;
                }
            }
            if (newQuantityDate < 0) {
                newQuantityDate = 0;
            }
            if (newQuantityDate > 0) {
                newQuantityDate = roundTo(newQuantityDate);
            }
            p.quantity = newQuantityDate;
            var value = p.quantity % productInCart.multiplicity;
            if (value > 0) {
                scope.controlTime[p.id] = setTimeout(function () {
                    if (value >= productInCart.multiplicity / 2) {
                        p.quantity += productInCart.multiplicity - value;
                    } else {
                        p.quantity -= value;
                    }
                    scope.$apply();
                }, 1000);
            } else {
                scope.calcBalance(p);
            }
        };
        
    }]);

    deliveryApp.controller('SummaryCtrl', ['$scope', '$http', function (scope, http) {
        window.scrollTo(0, 0);
        scope.step.title = 'Resumo e confirmação';
        scope.step.actionNextStepText = 'Confirmar';
        scope.step.indicator = 4;
        scope.step.nextTitle = '\u00A0';
        scope.step.creditValid = false;
        scope.step.calcCoords();
        scope.step.actionNextStep = function () {
            scope.isLoading = true;
            let deliveryData = [];
            let listProductsId = [];
            let listDeliveryId = [];
            let listToDelete = scope.base.selectedDeliveryId;
            let itineraryDays = scope.base.deliveryData.itineraryDays;
            if (scope.base.currOpp.hasOwnProperty('selectedTerritory')) {
                if (scope.base.currOpp.selectedTerritory) {
                    if (scope.base.currOpp.selectedTerritory.hasOwnProperty('$$hashKey')) {
                        delete scope.base.currOpp.selectedTerritory.$$hashKey;                    
                    }                    
                }
            }
            scope.base.currOpp.products.forEach(function (item, index) {
                let indexProd = listToDelete.indexOf(item.id);
                if (indexProd > -1) {
                    listToDelete.splice(indexProd, 1);
                }
                if (listProductsId.indexOf(item.productId) < 0) {
                    listProductsId.push(item.productId);
                }
                if (listDeliveryId.indexOf(item.id) < 0) {
                    listDeliveryId.push(item.id);
                }

                deliveryData.push({
                    id:                     item.id,
                    oppId:                  scope.base.currOpp.id,
                    oppItemId:              item.itemId,
                    productId:              item.productId,
                    businessPlaceId:        (scope.base.currOpp.selectedBusinessPlace != null ? scope.base.currOpp.selectedBusinessPlace.id : null),
                    itineraryDays:          itineraryDays,
                    orderType:              scope.base.currOpp.orderType.value,
                    confirmed:              item.confirmed,
                    deliveryDate:           formatDateForm(item.deliveryDate),
                    selectedAccount:        scope.base.currOpp.selectedAccount.id,
                    receiver:               (scope.base.currOpp.orderType.value == 'Conta e Ordem' && item.receiver != null ? item.receiver.id : null),
                    shipper:                (scope.base.currOpp.orderType.value == 'Remanejamento' && scope.base.currOpp.shipper != null ? scope.base.currOpp.shipper.id : null),
                    quantity:               item.quantity,
                    liter:                  item.liter,
                    baseLiter:              item.baseLiter,
                    confirmedDate:          formatDateForm((item.confirmedDate != null ? item.confirmedDate  : new Date())),
                    orderNumber:            item.orderNumber,
                    territoryData:          scope.base.currOpp.selectedTerritory,
                    itineraryId:            scope.base.deliveryData.itineraryId,
                    guide:                  item.guide,
                    registrationNumber:     item.registrationNumber
                });     
            });
            console.log(deliveryData);
            console.log(listToDelete);
            console.log(listProductsId);
            console.log(listDeliveryId);
            console.log(scope.base.currOpp.id);
            debugger;
            callRemoteAction('DeliveryAppController.upsertDeliveryData', {
                listDeliveryData: deliveryData, 
                listToDelete: listToDelete,
                listProductsId: listProductsId,
                listDeliveryId: listDeliveryId,
                oppId: scope.base.currOpp.id,
                creditValid: scope.step.creditValid
            }, function (result, event) {
                console.log(result);
                scope.isLoading = false;
                scope.$apply();
                debugger;
                if (event.status) {                    
                    if (!result.hasErrors) {            
                        scope.base.selectedOpp      = null;
                        scope.base.selectedProducts = null;
                        scope.base.arrOpp           = [];
                        scope.base.arrOppFiltered   = [];
                        if (result.type == 'warning') {                            
                            let decoded = $('<div/>').html(result.message).text();
                            Swal.fire({
                                title: 'Atenção!',
                                html: decoded,
                                type: 'warning'
                            }).then((result) => {
                                Swal.fire({
                                    type: 'success',
                                    title: 'Show',
                                    text: 'A programação de entrega da oportunidade ' + scope.base.currOpp.name + ' foi atualizada com sucesso!',
                                });
                            });
                        }else {                            
                            Swal.fire({
                                type: 'success',
                                title: 'Show',
                                text: 'A programação de entrega da oportunidade ' + scope.base.currOpp.name + ' foi atualizada com sucesso!',
                            });
                        }
                        location.href = "#/opportunitylist";
                    } else {
                        if (result.message) {
                            Swal.fire({
                                title: 'Atenção',
                                html: result.message.split('\\n').join('<br>'),
                                type: 'warning',
                                showCancelButton: true,
                                confirmButtonColor: '#3085d6',
                                confirmButtonText: 'Sim',
                                cancelButtonText: 'Não'
                            }).then((result) => {
                                if (result.value) {
                                    scope.isLoading = true;
                                    scope.step.creditValid = true;
                                    scope.step.actionNextStep();
                                }
                            });
                        }
                        // Log.fire(result, '9884');
                    }
                }else {
                    Log.fire(null, '9844');
                }
            });
        };
        scope.step.showNextStep = function () {
            return !(scope.pageView == 'read');
        };
        scope.step.actionBackStep = function () {
            location.href = "#/ship";
        };
        scope.$parent.containerClass = 'summary';

        scope.$parent.summaryVision = false;

        scope.isLoading = false;

        var datesPerProducts = Object.keys(scope.ship.dates);

        for (const key in scope.base.currOpp.products) {
            const product = scope.base.currOpp.products[key];
            product.shipDates = datesPerProducts.filter(function (value) {
                return scope.ship.dates[value].hasOwnProperty(key);
            });
        }

        scope.summaryProducts = [];

        scope.init = function () {
            scope.base.currOpp.products.forEach(function (item) {
                let currProd = scope.summaryProducts.find(a => a.productId == item.productId);
                if (!currProd) {
                    scope.summaryProducts.push({
                        productId: item.productId,
                        name: item.name,
                        quantity: item.quantity
                    });
                }else {
                    currProd.quantity += item.quantity;
                }
            });
        };

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

        scope.formatPrice = function (price) {
            return formatMonetary(price, 2);
        };

        scope.calcTotalCartValue = function () {
            scope.cart.total = scope.base.currOpp.products.reduce(function (sum, num) {
                return sum + num.totalValue;
            }, 0);
            scope.cart.totalInterest = scope.base.currOpp.products.reduce(function (sum, num) {
                return sum + num.totalValueWithInterest;
            }, 0);
            return scope.formatPrice(scope.cart.totalInterest);
        };

        scope.calcTotalCartValueDolar = function () {
            scope.cart.totalDolar = scope.cart.total / scope.base.dolar;
            scope.cart.totalDolarInterest = scope.cart.totalInterest / scope.base.dolar;
            return scope.formatPrice(scope.cart.totalDolarInterest);
        };

    }]);

    deliveryApp.controller('SectionCtrl', ['$scope', function (scope) {

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

})();

function roundTo(n, digits) {
    if (digits === undefined) {
        digits = 0;
    }

    var multiplicator = Math.pow(10, digits);
    n = parseFloat((n * multiplicator).toFixed(11));
    return Math.round(n) / multiplicator;
}

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

function sSize(VAR_text) {
    return (VAR_text < 10 ? '0' + VAR_text : VAR_text)
}

function formatDate(date) {
    if (typeof date == 'string' || typeof date == 'number') {
        date = new Date(date);
    }
    if (!(date instanceof Date)) {
        return false;
    }
    return sSize(date.getUTCDate()) + '/' + sSize(date.getUTCMonth() + 1) + '/' + date.getUTCFullYear();
}

function formatDateForm(date) {
    if (typeof date == 'string' || typeof date == 'number') {
        date = new Date(date);
    }
    if (!(date instanceof Date)) {
        return false;
    }
    return sSize(date.getUTCFullYear()) + '-' + sSize(date.getUTCMonth() + 1) + '-' + sSize(date.getUTCDate());
}

function compareDates(VAR_d1, VAR_d2) {
    if (typeof VAR_d1 == 'string' || typeof VAR_d1 == 'number') {
        VAR_d1 = new Date(VAR_d1);
    }
    if (typeof VAR_d2 == 'string' || typeof VAR_d2 == 'number') {
        VAR_d2 = new Date(VAR_d2);
    }
    if (!(VAR_d1 instanceof Date) || !(VAR_d2 instanceof Date)) {
        return false;
    }
    VAR_d1 = VAR_d1.getUTCFullYear() + '-' + VAR_d1.getUTCMonth() + '-' + VAR_d1.getUTCDate();
    VAR_d2 = VAR_d2.getUTCFullYear() + '-' + VAR_d2.getUTCMonth() + '-' + VAR_d2.getUTCDate();
    if (VAR_d1 == VAR_d2) {
        return true;
    }
    return false;
}

function compareMonths(VAR_d1, VAR_d2) {
    if (typeof VAR_d1 == 'string' || typeof VAR_d1 == 'number') {
        VAR_d1 = new Date(VAR_d1);
    }
    if (typeof VAR_d2 == 'string' || typeof VAR_d2 == 'number') {
        VAR_d2 = new Date(VAR_d2);
    }
    if (!(VAR_d1 instanceof Date) || !(VAR_d2 instanceof Date)) {
        return false;
    }
    VAR_d1 = VAR_d1.getUTCFullYear() + '-' + VAR_d1.getUTCMonth();
    VAR_d2 = VAR_d2.getUTCFullYear() + '-' + VAR_d2.getUTCMonth();
    if (VAR_d1 == VAR_d2) {
        return true;
    }
    return false;
}

var calendar = {
    initDate: null,
    endDate: null,
    contextDate: null,
    multiple: false,
    selected: [],
    dates: [],
    avaliable: [],
    months: ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'],
};

function getWeekend(dt) {
    if (calendar.weekendAvaliable) {
        return true;
    }
    let weekendDays = [0, 6];
    if (weekendDays.indexOf(dt.getUTCDay()) > -1) {
        return false;
    }
    return true;
}

function isUnavailableDate(dt, unavailableDates) {
    if (typeof unavailableDates == 'undefined') {
        unavailableDates = calendar.unavailableDates;
    }
    if (unavailableDates.indexOf(formatDateForm(dt)) > -1) {
        return true;
    }
    return false;
}

function setDaysCalendar() {
    var currMonth = null;
    var contextDate = null;
    calendar.dates = [];
    contextDate = new Date(calendar.contextDate);
    contextDate.setUTCDate(1);
    currMonth = contextDate.getUTCMonth();
    while (contextDate.getUTCMonth() == currMonth) {
        calendar.dates.push(new Date(contextDate));
        contextDate.setUTCDate(contextDate.getUTCDate() + 1);
    }
    drawCalendar();
}

function initCalendar(id, options, callback) {
    var datesArray = [];
    for (var dateKey in options.dates) {
        datesArray.push(new Date(dateKey));
    }
    calendar.endDate = (datesArray.length > 0 ? new Date(Math.max.apply(null, datesArray)) : null);
    calendar.initDate = (datesArray.length > 0 ? new Date(Math.min.apply(null, datesArray)) : options.initDate);
    calendar.avaliable = options.dates;
    calendar.weekendAvaliable = options.weekendAvaliable;
    calendar.unavailableDates = options.unavailableDates;
    calendar.isOpen = options.isOpen;
    calendar.greaterThanInit = options.greaterThanInit;
    calendar.contextDate = new Date(calendar.initDate);
    calendar.callback = callback;
    document.getElementById(id).innerHTML = '<table class="calendar"></table>';

    if (typeof calendar.unavailableDates == 'undefined') {
        calendar.unavailableDates = [];
    }
    if (calendar.unavailableDates == null) {
        calendar.unavailableDates = [];
    }

    calendar.unavailableDates.forEach(function (item, index) {
        calendar.unavailableDates[index] = formatDateForm(item);
    });

    setDaysCalendar();
}

function drawCalendar() {
    if (calendar.initDate == 'Invalid Date' ||
        calendar.endDate == 'Invalid Date' ||
        calendar.contextDate == 'Invalid Date') {
        return false;
    }
    var html = '' +
        '<tr class="month">' +
        '	<td><div onclick="nextMonth(false);" class="' + (calendar.greaterThanInit ? (compareMonths(calendar.contextDate, calendar.initDate) ? 'disabled' : '') : '') + '"><svg class="slds-button__icon" aria-hidden="true"><use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevronleft"></use></svg></div></td>' +
        '	<td colspan="5" id="month">' + calendar.months[calendar.contextDate.getUTCMonth()] + ' <small>' + calendar.contextDate.getUTCFullYear() + '</small></td>' +
        '	<td><div onclick="nextMonth(true);" class="' + (!calendar.isOpen ? (compareMonths(calendar.contextDate, calendar.endDate) ? 'disabled' : '') : '') + '"><svg class="slds-button__icon" aria-hidden="true"><use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevronright"></use></svg></div></td>' +
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
    var colspan = calendar.dates[0].getUTCDay();
    var cols = 6;
    var dateFormated = null;
    for (var i = 0; i < calendar.dates.length; i++) {
        if (colspan > 0 && colspan < 7) {
            html += '' +
                '<td colspan="' + colspan + '"></td>';
            colspan = 0;
        }
        dateFormated = formatDateForm(calendar.dates[i]);
        html += '' +
            '	<td>' +
            '       <div onclick="selectDateCalendar(' + i + ', this);" class="wrapper ' + (calendar.selected.indexOf(dateFormated) > -1 ? 'active ' : '') + (compareDates(calendar.dates[i], new Date()) ? 'today' : '') + (!calendar.isOpen ? (Object.keys(calendar.avaliable).length > 0 ? (typeof calendar.avaliable[dateFormated] == 'undefined' ? ' disabled' : '') : ' disabled') : (calendar.greaterThanInit ? (dateFormated >= calendar.initDate ? '' : ' disabled') : '')) + (getWeekend(calendar.dates[i]) ? '' : ' disabled') + (isUnavailableDate(calendar.dates[i]) ? ' disabled' : ' ') + '">' +
            calendar.dates[i].getUTCDate() +
            '       </div>' +
            '   </td>';
        if (cols == calendar.dates[i].getUTCDay()) {
            html += '' +
                '</tr>' +
                '<tr>';
        }
    }
    document.getElementsByClassName('calendar')[0].innerHTML = html;
}

function selectDateCalendar(i, el) {
    if (calendar.multiple) {
        if (calendar.selected.indexOf(formatDateForm(calendar.dates[i])) > -1) {
            calendar.selected.splice([calendar.selected.indexOf(formatDateForm(calendar.dates[i]))], 1);
            el.classList.remove('active');
        } else {
            calendar.selected.push(formatDateForm(calendar.dates[i]));
            el.classList.add('active');
        }
    } else {
        var els = document.getElementsByClassName('calendar')[0].getElementsByClassName('wrapper');
        for (var j = 0; j < els.length; j++) {
            els[j].classList.remove('active');
        }
        if (calendar.selected.indexOf(formatDateForm(calendar.dates[i])) > -1) {
            calendar.selected.splice([calendar.selected.indexOf(formatDateForm(calendar.dates[i]))], 1);
            el.classList.remove('active');
        } else {
            calendar.selected = [];
            calendar.selected.push(formatDateForm(calendar.dates[i]));
            el.classList.add('active');
        }
    }
    calendar.callback(formatDateForm(calendar.dates[i]));
}

function nextMonth(next) {
    if (next) {
        calendar.contextDate.setUTCMonth(calendar.contextDate.getUTCMonth() + 1);
    } else {
        calendar.contextDate.setUTCMonth(calendar.contextDate.getUTCMonth() - 1);
    }
    setDaysCalendar();
}

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

function areDatesEqual(VAR_d1, VAR_d2) {
    if (typeof VAR_d1 == 'string' || typeof VAR_d1 == 'number') {
        VAR_d1 = new Date(VAR_d1);
    }
    if (typeof VAR_d2 == 'string' || typeof VAR_d2 == 'number') {
        VAR_d2 = new Date(VAR_d2);
    }
    if (!(VAR_d1 instanceof Date) || !(VAR_d2 instanceof Date)) {
        return false;
    }
    VAR_d1 = VAR_d1.getUTCFullYear() + '-' + VAR_d1.getUTCMonth() + '-' + VAR_d1.getUTCDate();
    VAR_d2 = VAR_d2.getUTCFullYear() + '-' + VAR_d2.getUTCMonth() + '-' + VAR_d2.getUTCDate();
    if (VAR_d1 == VAR_d2) {
        return true;
    }
    return false;
}

function isEqualOrGreaterThan(d1, d2) {
    if (typeof d1 == 'string' || typeof d1 == 'number') {
        d1 = new Date(d1);
    }
    if (typeof d2 == 'string' || typeof d2 == 'number') {
        d2 = new Date(d2);
    }

    if (!(d1 instanceof Date) || !(d2 instanceof Date)) {
        return false;
    }

    return d1.getTime() > d2.getTime() || areDatesEqual(d1, d2);
}

function isDateInRange(dt, d1, d2) {
    if (typeof dt == 'string' || typeof dt == 'number') {
        dt = new Date(dt);
    }
    if (typeof d1 == 'string' || typeof d1 == 'number') {
        d1 = new Date(d1);
    }
    if (typeof d2 == 'string' || typeof d2 == 'number') {
        d2 = new Date(d2);
    }

    if (!(dt instanceof Date) || !(d1 instanceof Date) || !(d2 instanceof Date)) {
        return false;
    }

    return (dt.getTime() > d1.getTime() && dt.getTime() < d2.getTime()) || (areDatesEqual(dt, d1) || areDatesEqual(dt, d2));
}

function isWeekend(dt) {
    let weekendDays = [0, 6];
    if (weekendDays.indexOf(dt.getUTCDay()) > -1) {
        return true;
    }
    return false;
}

function getBusinessDate(currDate, days, unavailableDates, add) {
    let targetDate = new Date(currDate);
    do {
        targetDate.setDate(targetDate.getDate() + ( 1 * (add ? 1 : -1) ) );
        if (isWeekend(targetDate)) {
            continue;
        }
        if (isUnavailableDate(targetDate, unavailableDates)) {
            continue;
        }
        days--;
    } while(days > 0);
    return targetDate;
}

const Toast = Swal.mixin({
    toast: true,
    position: 'top-end',
    showConfirmButton: false,
    timer: 3000
});

const defaultErrorMessage = 'Algo deu errado, tente novamente. Se o problema persistir, contate um Administrador do Sistema.';

function Log() {
    this.showErrorMessage = function (ex, code) {
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
        if (typeof code == 'undefined') {
            code = null;
        }
        let html = ex.message + ' <br/>';
        if (ex.stackStrace != null) {
            html +=  ''+
                '<div class="collapsible left">'+
                '   <input type="checkbox" id="log" />'+
                '   <div class="collapsible-header">'+
                '       <label for="log">'+
                '           <svg class="slds-button__icon collapsible-down" aria-hidden="true">'+
                '               <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevrondown"></use>'+
                '           </svg>'+
                '           <svg class="slds-button__icon collapsible-up" aria-hidden="true">'+
                '               <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevronup"></use>'+
                '           </svg>'+
                '           <small>' + (code != null ? 'CODE: [' + code + ']' : 'Ver log') + '</small>' +
                '       </label>'+
                '   </div>'+
                '   <div class="collapsible-body">' + ex.stackStrace + '</div>'+
                '</div>'
            ;
        } else if (code != null) {
            html +=  ''+
                '<div class="collapsible">'+
                '   <div class="collapsible-header">'+
                '       <label for="log">'+
                '           <small>CODE: [' + code + ']</small>' +
                '       </label>'+
                '   </div>'+
                '</div>'
            ;
        }
        Swal.fire({
            type: 'warning',
            title: 'Oops...',
            html: html,
        });
    };
}

Log.fire = function (ex, code) {
    new Log().showErrorMessage(ex, code);
};

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
        if (weekendDays.indexOf(dt.getUTCDay()) > -1) {
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
        contextDate.setUTCDate(1);
        currMonth = contextDate.getUTCMonth();
        while (contextDate.getUTCMonth() == currMonth) {
            this.dates.push(new Date(contextDate));
            contextDate.setUTCDate(contextDate.getUTCDate() + 1);
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
            '	<td colspan="5" id="month">' + this.months[this.contextDate.getUTCMonth()] + ' <small>' + this.contextDate.getUTCFullYear() + '</small></td>' +
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
        var colspan = this.dates[0].getUTCDay();
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
                this.dates[i].getUTCDate() +
                '       </div>' +
                '   </td>';
            if (cols == this.dates[i].getUTCDay()) {
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
            this.contextDate.setUTCMonth(this.contextDate.getUTCMonth() + 1);
        } else {
            this.contextDate.setUTCMonth(this.contextDate.getUTCMonth() - 1);
        }
        this.setDaysCalendar();
    };
};

Calendar.counter = 0;

Calendar.create = function (id, options, callback) {
    return new Calendar().initCalendar(id, options, callback);
};

