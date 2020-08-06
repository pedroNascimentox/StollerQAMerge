
(function () {
    var deliveryChangeApp = angular.module('deliveryChangeApp', ['ngRoute', 'sf-lookup', 'floating-button']);

    deliveryChangeApp.config(function ($routeProvider) {
        $routeProvider.
        when('/opportunitylist', {
            templateUrl: window.URLS.deliveryChangeAppOpportunityList,
            controller: 'OpportunityCtrl'
        }).
        when('/header', {
            templateUrl: window.URLS.deliveryChangeAppHeader,
            controller: 'HeaderCtrl'
        }).
        when('/summary', {
            templateUrl: window.URLS.deliveryChangeAppSummary,
            controller: 'SummaryCtrl'
        }).
        otherwise({
            redirectTo: '/opportunitylist'
        });
    });

    deliveryChangeApp.controller('DeliveryCtrl', ['$scope', '$http', '$sce', '$filter', function (scope, http, $sce, $filter) {

        scope.pageView = 'insert';
        scope.oppStatus = '';
        scope.controlTime = {};

        scope.isMultiple = function (p) {
            let productInCart = scope.base.selectedProducts.find(function (item) {
                return item.productId == p.productId;
            });
            return p.quantity % productInCart.multiplicity == 0;
        };
        
        scope.oppId             = oppId;
        scope.oppName           = oppName;
        scope.isCustomerService = isCustomerService;
        
        if (scope.oppId > ' ') {
            scope.pageView = 'read';
        }

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
            quantityStep: 3,
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
            callRemoteAction('DeliveryChangeAppController.getBaseData', function (result, event) {
                console.log(result);
                if (!result.hasErrors) {
                    scope.base.confirmationDeadlineDays = result.data.confirmationDeadlineDays;
                    scope.base.changeReasons    = result.data.orderReasons;
                    scope.base.changeTypes      = result.data.changeTypes;
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

    }]);

    deliveryChangeApp.controller('OpportunityCtrl', ['$scope', '$http', function (scope, http) {

        scope.isLoading = true;

        scope.callRemote = function () {
            scope.isLoading = true;
            callRemoteAction('DeliveryChangeAppController.getOpportunityListData', function (result, event) {
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
                                    orderCreatedDate: true,
                                    orderNumber: true,
                                    regional: true,
                                    rtvName: true,
                                    selectedAccount: true,
                                    selectedProduct: true
                                };
                                if (scope.filter.selectedAccount != null) {
                                    checks.selectedAccount = scope.filter.selectedAccount.id == product.selectedAccount.id;
                                }
                                if (scope.filter.selectedProduct != null) {
                                    checks.selectedProduct = scope.filter.selectedProduct.id == product.productId;
                                }
                                if (scope.filter.orderCreatedDate != null) {
                                    checks.orderCreatedDate = scope.filter.orderCreatedDate == formatDateForm(product.orderCreatedDate);
                                }
                                if (scope.filter.rtvName != null) {
                                    checks.rtvName = product.hasOwnProperty('rtvName') && product.rtvName.toLowerCase().indexOf(scope.filter.rtvName.toLowerCase()) > -1;
                                }
                                if (scope.filter.regional != null) {
                                    checks.regional = product.hasOwnProperty('regionalName') && product.regionalName.toLowerCase().indexOf(scope.filter.regional.toLowerCase()) > -1;
                                }
                                if (scope.filter.oppNumber != null) {
                                    checks.oppNumber = product.hasOwnProperty('oppNumber') && product.oppNumber.toLowerCase().indexOf(scope.filter.oppNumber.toLowerCase()) > -1;
                                }
                                if (scope.filter.orderNumber != null) {
                                    checks.orderNumber = product.hasOwnProperty('orderNumber') && product.orderNumber.toLowerCase().indexOf(scope.filter.orderNumber.toLowerCase()) > -1;
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
                        console.log(scope.base.arrOppFiltered);
                        scope.base.arrOppFiltered = scope.base.arrOpp;
                        if (scope.base.selectedOpp != null) {
                            if (!scope.base.arrOppFiltered.find(a => a.id == scope.base.selectedOpp.id)) {
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

        scope.callRemote();

        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.step.title = 'Programações de Entrega';
        scope.step.actionNextStepText = 'Avançar';
        scope.step.indicator = 1;
        scope.step.nextTitle = 'Próximo: Alteração de datas de entrega';
        scope.step.actionNextStep = function () {
            scope.isLoading = true;
            if (scope.base.selectedOpp) {
                let opp = Object.assign({}, scope.base.arrOpp.find(a => a.id == scope.base.selectedOpp.id));
                let selectedProducts = scope.base.selectedOpp.products.filter(function (item) {
                    return item.selected;
                });
                scope.base.selectedProducts = selectedProducts;
                scope.base.selectedProducts.forEach(a => {
                    a.originalDate = formatDate(a.deliveryDate);
                    a.balance = a.quantity;
                });
                opp.products = JSON.parse(JSON.stringify(scope.base.selectedProducts));
                scope.base.currOpp = opp;
                scope.base.currOpp.selected = false;

                callRemoteAction('DeliveryChangeAppController.getDeliveryData', scope.base.currOpp.products[0].oppId, function (result, event) {
                    if (event.status) {
                        if (!result.hasErrors) {
                            scope.base.deliveryData = result.data;
                            scope.ship.defaultDate = formatDateForm(result.data.minimumDate);
                            scope.isLoading = false;
                            scope.ship.currentDate = null;
                            let arrProducts = [];
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
                            let balances = {};
                            scope.base.currOpp.products = arrProducts;
                            scope.base.currOpp.products.forEach(function (item, index) {
                                if (!balances.hasOwnProperty(item.productId)) {
                                    balances[item.productId] = 0;
                                }
                                balances[item.productId] += item.quantity;
                                let dt = item.deliveryDate = formatDateForm(item.deliveryDate);
                                if (scope.ship.currentDate == null || scope.ship.currentDate > dt) {
                                    scope.ship.currentDate = dt;
                                }
                                item.initBillingDate    = item.billingDate;
                                item.initDeliveryDate   = item.deliveryDate;
                                item.initQuantity       = item.quantity;
                                item.totalValue         = item.quantity * item.salesPriceWithInterest;
                                item.totalValueDolar    = item.totalValue;
                                if (item.oppCurrency == 'BRL') {
                                    item.totalValueDolar = item.totalValueDolar * item.dolar;
                                }else {
                                    item.totalValue = item.totalValue / item.dolar;
                                }
                                // if (isEqualOrGreaterThan(scope.ship.defaultDate, item.deliveryDate)) {
                                //     item.deliveryDate = scope.ship.defaultDate;
                                // }
                                item.deliveryDateFormated = formatDate(item.deliveryDate);
                            });
                            for (const key in balances) {
                                (scope.base.selectedProducts.find(a => a.productId == key) || {}).quantity = balances[key];
                            }
                            Swal.fire({
                                title: 'Alteração de Data',
                                html: 'Selecione uma opção de alteração de data de entrega.',
                                type: 'info',
                                showCancelButton: true,
                                confirmButtonColor: '#3085d6',
                                confirmButtonText: 'Total',
                                cancelButtonText: 'Parcial',
                                allowOutsideClick: false,
                                allowEscapeKey: false
                            }).then((result) => {
                                if (result.value) {
                                    scope.base.currOpp.changeType = {label: 'Total', value: 'Total'};
                                    scope.$apply();
                                }else {
                                    scope.base.currOpp.changeType = {label: 'Parcial', value: 'Parcial'};
                                    scope.$apply();
                                }
                            });
                            location.href = "#/header";
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

        scope.selectAllItems = function (oppId) {
            let opp = scope.base.arrOppFiltered.find(a => a.id == oppId);
            opp.products.forEach(function (item, index) {
                item.selected = opp.selected;
            });
            scope.setSelectedOpp();
        };

        scope.validateSelectedOpp = function (oppId) {
            let opp = scope.base.arrOppFiltered.find(a => a.id == oppId);
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

        scope.isSelectedOpp = function (oppId) {
            return (scope.base.selectedOpp != null ? scope.base.selectedOpp.id == oppId ? '' : 'disabled' : '');
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

        scope.setCalendarCreatedDate = function (dt, name) {
            scope.filter.orderCreatedDate = dt;
            scope.filter.orderCreatedDateFormated = formatDate(dt);
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
            scope.setCalendarCreatedDate(result, name);
        });

        scope.calendarVisibility[calendarDeliveryDate.name] = false;

        scope.clearOrderCreatedDate = function () {
            scope.filter.orderCreatedDate = null;
            scope.filter.orderCreatedDateFormated = null;
        };

        scope.advancedFilterOpp = function () {
            scope.filter.open = false;
            scope.callRemote();
        };

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

    deliveryChangeApp.controller('HeaderCtrl', ['$scope', '$http', function (scope, $http) {

        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.step.title = 'Alterações de envio';
        scope.step.actionNextStepText = 'Avançar';
        scope.step.indicator = 2;
        scope.step.nextTitle = 'Próximo: Resumo e confirmação';
        scope.step.calcCoords();
        scope.step.actionNextStep = function () {
            scope.ship.currentDate = null;
            let arrProducts = [];
            scope.base.currOpp.products.forEach(function (item) {
                item.receiver = scope.base.currOpp.receiver;
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
            location.href = "#/summary";
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
                    scope.base.selectedOpp = null;
                    scope.base.selectedProducts = null;
                    scope.base.arrOpp = [];
                    scope.base.arrOppFiltered = [];
                    scope.base.currOpp.products = [];
                    location.href = "#/productlist";
                }
            });
        };
        scope.step.showNextStep = function () {
            let allProductsHaveQuantity = true;
            let multiplicityOk = true;
            let datesOk = true;
            scope.base.currOpp.products.forEach(function (item) {
                if (item.quantity <= 0) {
                    allProductsHaveQuantity = false;
                }
                if (item.quantity % item.multiplicity > 0) {
                    multiplicityOk = false;
                }
                if (item.deliveryDateFormated == item.originalDate) {
                    datesOk = false;
                }
            });
            return scope.base.currOpp.changeReason != null && allProductsHaveQuantity && multiplicityOk && datesOk;
        };

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

        scope.setDefaultDeliveryDate = function () {
            let dt = scope.default.deliveryDate;
            scope.base.currOpp.products.forEach(function (item) {
                item.deliveryDate = dt;
                item.billingDate = formatDateForm(getBusinessDate(dt, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false))
            });
        };

        scope.openCalendar = function (name) {
            scope.calendarVisibility[name] = !scope.calendarVisibility[name];
        };

        scope.showCalendar = false;
        scope.showMoreDates = true;

        scope.isValidDate = function (item) {
            if (typeof item.billingDate == 'undefined') {
                item.billingDate = formatDateForm(getBusinessDate(item.deliveryDate, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false));
            }
            let confirmationDeadlineDate = new Date(item.billingDate);
            confirmationDeadlineDate.setDate(confirmationDeadlineDate.getDate() - scope.base.confirmationDeadlineDays);
            if (isEqualOrGreaterThan(item.deliveryDate, scope.ship.defaultDate) && isDateInRange(new Date(), confirmationDeadlineDate, item.billingDate)) {
                return true;
            }
            item.confirmed = false;
            return false;
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
            // scope.inspectorShip();
            return productInCart.balance;
        };
        scope.increment = function (p) {
            scope.quantityChange(p, true, true);
        };

        scope.decrement = function (p) {
            scope.quantityChange(p, true, false);
        };

        scope.quantityChange = function (p, helper, plus) {
            if (!p.quantity){
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

        scope.calendarName = function (product) {
            return 'calendar-' + product.id;
        };

        scope.setCalendarDeliveryDate = function (dt, name, item) {
            item.deliveryDate = dt;
            item.deliveryDateFormated = formatDate(dt);
            scope.openCalendar(name);
            scope.$apply();
        };

        angular.element(document).ready(function () {
            scope.base.currOpp.products.forEach(function (item) {
                calendarDeliveryDate = Calendar.create('wrapper-calendar-' + item.id, {
                    dates: {},
                    name: 'calendar-' + item.id,
                    initDate: scope.ship.defaultDate,
                    isOpen: true,
                    greaterThanInit: true,
                    weekendAvaliable: false,
                    unavailableDates: scope.base.unavailableDates
                }, function (result, name) {
                    scope.setCalendarDeliveryDate(result, name, item);
                });

                scope.calendarVisibility[calendarDeliveryDate.name] = false;
            });
        });

        scope.ruleChangeType = function () {
            if (scope.base.currOpp.changeType.value == 'Total') {
                scope.base.currOpp.products.forEach(function (item) {
                    item.quantity = item.initQuantity;
                });
            }
        };

        scope.calcTotalValue = function (product, isDolar) {
            if (product.oppCurrency == 'USD') {
                product.salesPriceWithInterest = product.salesPriceWithInterest / product.dolar;
            }
            product.totalValue      = product.quantity * product.salesPriceWithInterest;
            product.totalValueDolar = product.totalValue;
            if (product.oppCurrency == 'BRL') {
                product.totalValueDolar = product.totalValue / product.dolar;
            } else {
                product.totalValue = product.totalValue * product.dolar;
            }
            if (product.oppCurrency == 'USD') {
                product.salesPriceWithInterest = product.salesPriceWithInterest * product.dolar;
            }
            if (isDolar) {
                return formatMonetary(product.totalValueDolar);
            }
            return formatMonetary(product.totalValue);
        };

    }]);

    deliveryChangeApp.controller('SummaryCtrl', ['$scope', '$http', function (scope, http) {
        window.scrollTo(0, 0);
        scope.step.title = 'Resumo e confirmação';
        scope.step.actionNextStepText = 'Solicitar Aprovação';
        scope.step.indicator = 3;
        scope.step.nextTitle = '\u00A0';
        scope.step.calcCoords();
        scope.step.actionNextStep = function () {
            scope.isLoading = true;
            let deliveryData = [];
            let listId = [];
            scope.base.currOpp.products.forEach(function (item) {
                listId.push(item.id);
                deliveryData.push({
                    id:                item.id,
                    orderItemId:       item.orderItemId,
                    deliveryDate:      formatDateForm(item.deliveryDate),
                    quantity:          item.quantity,
                    billingDate:       formatDateForm(getBusinessDate(item.deliveryDate, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false)),
                    totalValue:        item.totalValue,
                    totalValueDolar:   item.totalValueDolar,
                    oppCurrency:       item.oppCurrency
                });
            });
            debugger;
            callRemoteAction('DeliveryChangeAppController.createChangeDelivery', {
                changeType: scope.base.currOpp.changeType.value,
                changeReason: scope.base.currOpp.changeReason.value,
                description: scope.base.currOpp.description,
                orderId: scope.base.currOpp.id,
                listDeliveryChangeData: deliveryData,
                listId: listId
            }, function (result, event) {
                console.log(result);
                scope.isLoading = false;
                scope.$apply();
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
                                    html: 'Alteração de data para o Pedido <strong>' + scope.base.currOpp.name + '</strong> foi solicitada com sucesso!',
                                });
                            });
                        }else {                            
                            Swal.fire({
                                type: 'success',
                                title: 'Show',
                                html: 'Alteração de data para o Pedido <strong>' + scope.base.currOpp.name + '</strong> foi solicitada com sucesso!',
                            });
                        }
                        location.href = "#/opportunitylist";
                    } else {
                        Log.fire(result, '9884');
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
            location.href = "#/header";
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

    deliveryChangeApp.controller('SectionCtrl', ['$scope', function (scope) {

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
    if (weekendDays.indexOf(dt.getDay()) > -1) {
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
    contextDate.setDate(1);
    currMonth = contextDate.getMonth();
    while (contextDate.getMonth() == currMonth) {
        calendar.dates.push(new Date(contextDate));
        contextDate.setDate(contextDate.getDate() + 1);
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
        '	<td colspan="5" id="month">' + calendar.months[calendar.contextDate.getMonth()] + ' <small>' + calendar.contextDate.getFullYear() + '</small></td>' +
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
    var colspan = calendar.dates[0].getDay();
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
            calendar.dates[i].getDate() +
            '       </div>' +
            '   </td>';
        if (cols == calendar.dates[i].getDay()) {
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
        calendar.contextDate.setMonth(calendar.contextDate.getMonth() + 1);
    } else {
        calendar.contextDate.setMonth(calendar.contextDate.getMonth() - 1);
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
    VAR_d1 = VAR_d1.getFullYear() + '-' + VAR_d1.getMonth() + '-' + VAR_d1.getDate();
    VAR_d2 = VAR_d2.getFullYear() + '-' + VAR_d2.getMonth() + '-' + VAR_d2.getDate();
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
    if (weekendDays.indexOf(dt.getDay()) > -1) {
        return true;
    }
    return false;
}

function getBusinessDate(currDate, days, unavailableDates, add) {
    let targetDate = new Date(typeof currDate == 'string' ? (currDate + 'T12:00') : currDate);
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