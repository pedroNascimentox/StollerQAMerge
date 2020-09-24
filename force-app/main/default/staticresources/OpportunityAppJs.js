(function () {
    var shoppingCartApp = angular.module('shoppingCartApp', ['ngRoute', 'sf-lookup', 'floating-button']);

    shoppingCartApp.controller('ShoppingCtrl', ['$scope', '$http', '$sce', '$filter', function (scope, http, $sce, $filter) {

        scope.pageView = 'insert';
        scope.oppStatus = '';
        scope.isPDFGenerator = isPDFGenerator;
        scope.controlTime = {};

        scope.isCustomerService = window.isCustomerService;
        
        scope.oppId             = oppId;
        scope.oppName           = oppName;
        scope.hasMasterAccess   = window.isCustomerService;

        if (scope.hasMasterAccess) {
            console.log('Customer Service!!');
        }
        
        if (scope.oppId > ' ') {
            scope.pageView = 'read';
        }

        scope.isMultiple = function (p) {
            let productInCart = scope.cart.products.find(function (item) {
                return item.id == p.id;
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
                obsInternal: '',
                obsLogistic: '',
                obsPrint: '',
                obsPrintNF: '',
                oppId: null
            },
            ship: {
                defaultDate: '2019-11-03',
                currentDate: '',
                dates: [],
                products: []
            },
            products: []
        };
        scope.base = {
            dolar: 4.16,
            priceReferenceDate: new Date(),
            priceReferenceDateFormated: formatDate(new Date()),
            priceAppData: {
                customerTypeDiscount: null,
                freightPercentage: null
            },
            currentCurrencyLabel: 'R$',
            unavailableDates: [],
            territoryData: {},
            internalDeadlineDays: null,
            itineraryDays: null,
            objProducts: {},
            freightTypes: [],
            currencies: [],
            paymentConditions: [],
            expeditions: [],
            orderTypes: [],
            orderReasons: [],
            salesClassifications: [],
            cultures: [],
            filteredPaymentConditions: []
        };
        scope.cart.header.referenceDateFormatted = formatDate(new Date());
        scope.calendarVisibility = {};

        scope.init = function () {
            callRemoteAction('OpportunityAppController.getBaseData', function (result, event) {
                console.log(result);
                if (event.status) {
                    if (!result.hasErrors) {
                        scope.base.currencies = result.data.currencies;
                        scope.base.cultures = result.data.cultures;
                        scope.base.orderTypes = result.data.orderTypes;
                        scope.base.expeditions = result.data.shipmentConditions;
                        scope.base.paymentConditions = result.data.paymentConditions;
                        scope.base.salesClassifications = result.data.salesClassifications;
                        scope.base.orderReasons = result.data.orderReasons;
                        scope.base.freightTypes = result.data.freightTypes;
                        scope.base.deliveryQuantityLimit = result.data.deliveryQuantityLimit - 1;
                        var targetDate = new Date();
                        scope.cart.header = {
                            currency: scope.base.currencies.find(a => a.isDefault),
                            paymentCondition: scope.base.paymentConditions.find(a => a.isDefault),
                            expedition: scope.base.expeditions.find(a => a.isDefault),
                            orderType: scope.base.orderTypes.find(a => a.isDefault),
                            salesClassification: scope.base.salesClassifications.find(a => a.isDefault || a.value == 'Normal'),
                            culture: scope.base.cultures.find(a => a.isDefault),
                            orderReason: scope.base.orderReasons.find(a => a.isDefault),
                            targetCultures: scope.base.cultures.slice(),
                            selectedFreightType: scope.base.freightTypes.find(a => a.isDefault),
                            selectedBusinessPlace: null,
                            referenceDateFormatted: formatDate(targetDate),
                            priceReferenceDate: targetDate,
                            orderNumber: '',
                            receiverAccount: null,
                            shipperAccount: null,
                            selectedAccount: null,
                            selectedCampaign: null,
                            selectedTerritory: null,
                        };
                        scope.base.confirmationDeadlineDays = result.data.confirmationDeadlineDays;
                        scope.base.unavailableDates = [];
                        result.data.holidays.forEach(function (item) {
                            let dt = formatDateForm(item.ActivityDate);
                            if (scope.base.unavailableDates.indexOf(dt) < 0) {
                                scope.base.unavailableDates.push(dt);
                            }
                        });
                    }else {
                        scope.$apply();
                        Log.fire(result, {
                            code: '3456'
                        });
                    }

                    scope.base.arrProducts = [];
                    scope.base.dolar = result.data.dollarData.rate;

                    if (scope.pageView == 'read') {
                        scope.isLoading = true;
                        callRemoteAction('OpportunityAppController.getExistentOpportunityData', scope.oppId, function (resultOpp, eventOpp) {
                            console.log(resultOpp);
                            if (eventOpp.status) {
                                if (!resultOpp.hasErrors) {
                                    var opp = resultOpp.data;
                                    var pc = result.data.paymentConditions;

                                    scope.base.priceAppData = opp.priceAppData;
                                    scope.base.territoryData = opp.territoryData;
                                    scope.cart.header.selectedBusinessPlace = opp.businessPlaceData;
                                    scope.cart.header.selectedTerritory = scope.base.territoryData;
                                    scope.base.deliveryData = opp.deliveryData;
                                    scope.cart.ship.defaultDate = formatDateForm(scope.base.deliveryData.minimumDate);
                                    scope.accountTerritories = opp.accountTerritories;
                                    
                                    scope.base.priceReferenceDate = opp.priceReferenceDate;
                                    scope.cart.header.referenceDateFormatted = formatDate(scope.base.priceReferenceDate);
                                    scope.oppStatus = opp.status;

                                    scope.cart.header['oppId'] = opp.id;
                                    scope.cart.header['selectedAccount'] = opp.selectedAccountData;
                                    scope.cart.header['receiverAccount'] = opp.selectedReceiverData;
                                    scope.cart.header['shipperAccount'] = opp.selectedShipperData;
                                    scope.cart.header['obsInternal'] = opp.obsInternal;
                                    scope.cart.header['obsLogistic'] = opp.obsLogistic;
                                    scope.cart.header['obsPrint'] = opp.obsPrint;
                                    scope.cart.header['obsPrintNF'] = opp.obsPrintNF;

                                    scope.cart.header['orderReason'] = scope.base.orderReasons.find(a => a.value == opp.orderReason);
                                    scope.cart.header['currency'] = scope.base.currencies.find(a => a.value == opp.selectedCurrency);
                                    scope.cart.header['expedition'] = scope.base.expeditions.find(a => a.value == opp.shipmentCondition);
                                    scope.cart.header['orderType'] = scope.base.orderTypes.find(a => a.value == opp.orderType);
                                    scope.cart.header['salesClassification'] = scope.base.salesClassifications.find(a => a.value == opp.salesClassification);

                                    scope.cart.header['orderNumber'] = opp.orderNumber;
                                    scope.cart.header['selectedCampaign'] = opp.selectedCampaignData;

                                    scope.cart.header['interestStartDate'] = opp.interestStartDate;
                                    scope.cart.header['previousSelectedCampaign'] = opp.previousSelectedCampaign;

                                    scope.cart.header.vendorDate = opp.vendorDueDate;
                                    if (opp.vendorDueDate > ' ') {
                                        scope.cart.header.vendorDateFormated = formatDate(scope.cart.header.vendorDate);
                                    }

                                    scope.campaignFilter.find(a => a.fieldApiName == 'conta__c').value = (scope.cart.header.selectedAccount || {}).id;
                                    scope.campaignFilter.find(a => a.fieldApiName == 'moeda__c').value = (scope.cart.header.currency || {}).value;
                                    scope.campaignFilter.find(a => a.fieldApiName == 'territory__c').value = (scope.cart.header.selectedTerritory || {}).territory;

                                    scope.base.currentCurrencyLabel = (scope.cart.header.currency.value == 'BRL' ? 'R$' : 'US$');

                                    if (scope.cart.header.selectedCampaign == null || opp.selectedCampaignData.paymentConditions.length == 0) {
                                        scope.base.filteredPaymentConditions = scope.updatePaymentConditions(scope.base.paymentConditions);
                                    } else {
                                        scope.base.filteredPaymentConditions = scope.updatePaymentConditions(scope.cart.header.selectedCampaign.paymentConditions);
                                    }

                                    setTimeout(() => {
                                        scope.cart.header.paymentCondition = pc.find(a => a.id == opp.paymentCondition);
                                        scope.isLoading = false;
                                        scope.openFloatingButton();
                                        scope.$apply();
                                    }, 500);
                                    if (opp.hasOwnProperty('products')) {
                                        opp.products.forEach(function (item, index) {
                                            let currProduct = scope.base.arrProducts.find(p => p.id == item.id);
                                            if (typeof currProduct == 'undefined') {
                                                let product = {
                                                    id: item.id,
                                                    sku: item.sku,
                                                    itemId: item.itemId,
                                                    customerTypeDiscount: item.customerTypeDiscount,
                                                    customerTypeDiscountValue: item.customerTypeDiscountValue,
                                                    recent: false,
                                                    details: {},
                                                    freightPercentage: item.freightPercentage,
                                                    freightValue: item.freightValue,
                                                    internalDeadlineDays: item.internalDeadlineDays,
                                                    itineraryDays: item.itineraryDays,
                                                    quantityLiter: item.liter,
                                                    maxDiscount: item.maxDiscount,
                                                    minimumDiscount: item.minimumDiscount,
                                                    multiplicity: item.multiplicity,
                                                    name: item.productName,
                                                    pbEntry: item.pbEntry,
                                                    priceList: item.priceList,
                                                    priceListDolar: item.priceListDolar,
                                                    recommendedDiscount: item.recommendedDiscount,
                                                    sku: item.sku,
                                                    culture: item.selectedCulture,
                                                    cultureIds: item.cultureIds,
                                                    discount: item.discount,
                                                    quantity: item.quantity,
                                                    balance: 0,
                                                    receiver: item.selectedReceiverData,
                                                    shippingTableId: item.shippingTableId,
                                                    discountPolicyId: item.discountPolicyId,
                                                    priceEntryId: item.priceEntryId,
                                                    customerTypeDiscountId: item.customerTypeDiscountId,
                                                    priceFromTable: item.priceFromTable,
                                                    initialDate: item.initialDate,
                                                    finishDate: item.finishDate,
                                                    inCart: true,
                                                    ipiPercentage: item.ipiPercentage,
                                                    salesPriceDolar: item.salesPriceDolar,
                                                    salesPriceWithInterestDolar: item.salesPriceWithInterestDolar,
                                                    salesPrice: item.salesPrice,
                                                    salesPriceWithInterest: item.salesPriceWithInterest,
                                                    priceListRef: (scope.cart.header.currency.value == 'USD' ? item.priceListDolar : item.priceList)
                                                };
                                                scope.base.arrProducts.push(product);
                                            } else {
                                                currProduct.quantity += item.quantity;
                                                currProduct.quantityLiter += item.liter;
                                            }
                                            if (scope.cart.ship.dates.indexOf(item.deliveryDate) < 0) {
                                                scope.cart.ship.dates.push(item.deliveryDate);
                                            }
                                            scope.cart.ship.products.push({
                                                id: item.id,
                                                itemId: item.itemId,
                                                opportunityId: item.opportunityId,
                                                name: item.productName,
                                                orderNumber: (item.hasOwnProperty('orderNumber') ? item.orderNumber : ''),
                                                date: item.deliveryDate,
                                                quantity: item.quantity,
                                                receiverAccount: (item.hasOwnProperty('selectedReceiverData') ? item.selectedReceiverData : null),
                                                confirmed: item.confirmed,
                                                confirmationDate: item.confirmationDate
                                            });
                                        });
                                    }
                                    scope.$apply();
                                } else {
                                    scope.$apply();
                                    Log.fire(resultOpp, {
                                        code: '3456'
                                    });
                                }
                            } else {
                                scope.$apply();
                                Log.fire(eventOpp, {
                                    code: '8465'
                                });
                            }
                        });
                    }
                    scope.$apply();
                }else {
                    scope.$apply();
                    Log.fire(event, {
                        code: '8465'
                    });
                }
                
            });            
        };

        scope.trustAsHtml = function (html) {
            return $sce.trustAsHtml(html);
        };

        let accountFilters = [{
            fieldApiName: 'ParentId',
            operator: '=',
            value: (scope.cart.header.selectedAccount != null ? "'" + scope.cart.header.selectedAccount.id + "'" : 'null')
        }];

        scope.filterReceiverAccount = function () {
            let accId = 'null';
            if (scope.cart.header.selectedAccount != null) {
                accId = "'" + scope.cart.header.selectedAccount.id + "'";
                if (scope.cart.header.selectedAccount.hasOwnProperty('parentId')) {
                    if (scope.cart.header.selectedAccount.parentId != null) {
                        accId = "'" + scope.cart.header.selectedAccount.parentId + "'";
                    }
                }
            }
            accountFilters.find(a => a.fieldApiName == 'ParentId').value = accId;
            return accountFilters;
        };

        scope.accountFields = "CNPJ__c;Name;ExternalId__c;NomeFazenda__c;ShippingCity;ShippingState;";

        scope.accountSubTitleFunction = function (fields) {
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

        scope.businessPlaceFields = 'Codigo__c;Descricao__c;Name';

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
    
                if (fields.name){
                    values.push(fields.name.trim());
                }
                if (fields.Codigo__c){
                    values.push(fields.Codigo__c.trim());
                }
    
                return values.join(' • ');                
            }
        }
        
        scope.getCampaignSubtitle = function (a) {
            return [a.name, a.currencyName].join(' • ')
        }

        scope.territoryFieldsTarget = "territoryName;externalId;";

        scope.territoryFields = ['name', 'externalId', 'territoryName'];
        
        scope.getTerritorySubtitle = function (territory) {
            if (territory) {
                if (territory.hasOwnProperty('returningFields')) {

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

        scope.campaignFilter = [{
                fieldApiName: 'moeda__c'
            },
            {
                fieldApiName: 'conta__c'
            },
            {
                fieldApiName: 'territory__c'
            },
            {
                fieldApiName: 'dataVigenciaDe__c'
            },
            {
                fieldApiName: 'dataVigenciaAte__c'
            },
        ];

        scope.accountTerritories = [];

        scope.updateSelectedAccount = function () {
            scope.base.filteredPaymentConditions = scope.updatePaymentConditions(scope.base.paymentConditions);
            scope.campaignFilter.find(a => a.fieldApiName == 'conta__c').value = (scope.cart.header.selectedAccount || {}).id;
            scope.campaignFilter.find(a => a.fieldApiName == 'moeda__c').value = (scope.cart.header.currency || {}).value;
            scope.campaignFilter.find(a => a.fieldApiName == 'dataVigenciaDe__c').value = scope.base.priceReferenceDate;
            scope.campaignFilter.find(a => a.fieldApiName == 'dataVigenciaAte__c').value = scope.base.priceReferenceDate;
            
            if (scope.cart.header.selectedAccount == null) {
                scope.cart.header.selectedCampaign = null;
                scope.cart.header.paymentCondition = null;
                scope.cart.header.receiverAccount = null;
                scope.cart.header.shipperAccount = null;
                scope.cart.header.selectedTerritory = null;
                scope.cart.header.selectedBusinessPlace = null;
            } else {
                scope.accountTerritories = scope.cart.header.selectedAccount.territories;

                if (scope.isCustomerService && scope.accountTerritories.length == 1) {
                    scope.cart.header.selectedTerritory = scope.accountTerritories[0];
                    scope.campaignFilter.find(a => a.fieldApiName == 'territory__c').value = (scope.cart.header.selectedTerritory || {}).territory;
                }

                if (!scope.accountTerritories.length){
                    scope.cart.header.selectedAccount = null;
                    Log.fire({
                        message: 'A conta não tem território associado.'
                    });
                }

                if (scope.isCustomerService) {
                    scope.cart.header.selectedBusinessPlace = scope.cart.header.selectedAccount.businessPlace;
                }
            }
        };
        
        scope.updateReceiverAccount = function () {
            if (scope.cart.header.receiverAccount == null) {
                if (scope.cart.header.selectedAccount == null) {
                    scope.cart.header.selectedCampaign = null;
                    scope.cart.header.paymentCondition = null;
                    scope.cart.header.receiverAccount = null;
                    scope.cart.header.shipperAccount = null;
                    scope.cart.header.selectedTerritory = null;
                    scope.cart.header.selectedBusinessPlace = null;
                }else {
                    if (scope.isCustomerService && scope.cart.header.selectedAccount.hasOwnProperty('businessPlace')) {
                        scope.cart.header.selectedBusinessPlace = scope.cart.header.selectedAccount.businessPlace;
                    }
                }
            }else {
                if (scope.isCustomerService) {
                    scope.cart.header.selectedBusinessPlace = scope.cart.header.receiverAccount.businessPlace;
                }
            }
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
        
        scope.getCampaignTitle = function (campaign) {
            if (typeof campaign == 'undefined') {
                campaign = {};
            }
            if (typeof campaign.returningFields == 'undefined') {
                campaign.returningFields = {};
            }
            if (typeof campaign.returningFields.descricao__c == 'undefined') {
                campaign.returningFields.descricao__c = '';
            }
            return campaign.returningFields.descricao__c;
        };

        scope.getPaymentConditionSubTitle = function (paymentCondition) {
            return paymentCondition.type + ' • ' + paymentCondition.currencyOpt;
        };

        scope.territoryFields = ['territoryName', 'name', 'rtvName'];

        scope.updateTerritoryData = function () {
            scope.cart.header.selectedCampaign = null;
            scope.campaignFilter.find(a => a.fieldApiName == 'territory__c').value = (scope.cart.header.selectedTerritory || {}).territory;
        };
        
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

        scope.updateCurrency = function () {
            scope.campaignFilter.find(a => a.fieldApiName == 'moeda__c').value = (scope.cart.header.currency || {}).value;
            
            scope.cart.header.selectedCampaign = null;
            scope.cart.header.paymentCondition = null;

            let paymentConditions = scope.cart.header.selectedCampaign == null ? scope.base.paymentConditions : (
                scope.cart.header.selectedCampaign.paymentConditions.length ?
                scope.cart.header.selectedCampaign.paymentConditions :
                scope.base.paymentConditions
            );

            scope.base.filteredPaymentConditions = scope.updatePaymentConditions(paymentConditions);
            
            scope.cart.header.targetCultures = scope.cart.header.selectedCampaign == null || scope.cart.header.salesClassification.value.indexOf('Campanha') < 0 ? scope.base.cultures : (
                scope.cart.header.selectedCampaign.cultures.length ?
                scope.cart.header.selectedCampaign.cultures :
                scope.base.cultures
            );
        };

        scope.updateOrderType = function () {
            scope.cart.header.paymentCondition = null;
            let paymentConditions = scope.cart.header.selectedCampaign == null || scope.cart.header.salesClassification.value.indexOf('Campanha') < 0 ? scope.base.paymentConditions : (
                scope.cart.header.selectedCampaign.paymentConditions.length ?
                scope.cart.header.selectedCampaign.paymentConditions :
                scope.base.paymentConditions
            );
            scope.base.filteredPaymentConditions = scope.updatePaymentConditions(paymentConditions);
        };

        scope.updateSalesClassification = function(){
            scope.cart.header.selectedCampaign = null;
            scope.updateCampaign();
        };

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

        scope.setDate = function (dt, name) {
            scope.cart.header.vendorDate = dt;
            scope.cart.header.vendorDateFormated = scope.formatScopeDate(dt);
            scope.calendarVisibility[name] = false;
            scope.$apply();
        };

        scope.vendor = null;
        scope.updateVendorCalendar = function () {
            let dt = new Date();
            if (scope.cart.header.selectedCampaign != null) {
                dt = new Date(scope.cart.header.selectedCampaign.returningFields.dataInicioJuros__c);
            }
            dt.setDate(dt.getDate() + 120);
            scope.vendor = Calendar.create('wrapper-calendar-vendor', {
                dates: {},
                initDate: formatDateForm(dt),
                isOpen: true,
                name: 'calendar-vendor',
                greaterThanInit: true,
                weekendAvaliable: true
            }, function (result, name) {
                scope.setDate(result, name);
            });

            scope.calendarVisibility[scope.vendor.name] = false;
        };


        scope.updateCampaign = function () {
            let paymentConditions = scope.cart.header.selectedCampaign == null || scope.cart.header.salesClassification.value.indexOf('Campanha') < 0 ? scope.base.paymentConditions : (
                scope.cart.header.selectedCampaign.paymentConditions.length ?
                scope.cart.header.selectedCampaign.paymentConditions :
                scope.base.paymentConditions
            );
            scope.cart.header.paymentCondition = null;
            scope.base.filteredPaymentConditions = scope.updatePaymentConditions(paymentConditions);
            scope.cart.header.targetCultures = scope.cart.header.selectedCampaign == null || scope.cart.header.salesClassification.value.indexOf('Campanha') < 0 ? scope.base.cultures : (
                scope.cart.header.selectedCampaign.cultures.length ?
                scope.cart.header.selectedCampaign.cultures :
                scope.base.cultures
            );
            scope.updateVendorCalendar();
        };

        scope.hasAccount = function () {
            return scope.cart.header.selectedAccount != null
        };

        scope.hasAccountForCampaign = function () {
            let territory = true;
            if (scope.isCustomerService) {
                if (scope.cart.header.selectedTerritory == null) {
                    territory = false;
                }
            }
            return scope.cart.header.selectedAccount != null && territory
        };

        scope.updatePaymentConditions = function (conditions) {
            if (scope.cart.header.selectedAccount == null) {
                return [];
            }
            paymentConditionsFilter = conditions.filter(function (item) {
                let show = true;
                if (item.type) {
                    if (scope.cart.header.orderType != null) {
                        if (scope.cart.header.orderType.value == 'Bonificação') {
                            if (item.days > 0 || (item.type != 'B' && item.type != 'U')  ) {
                                return false;
                            }
                        }                        
                    }
                    if (item.type == 'Vendor' || item.type == 'V') {
                        if (scope.cart.header.selectedAccount.paymentRating != 'A' && scope.cart.header.selectedAccount.paymentRating != 'B' && scope.cart.header.selectedAccount.paymentRating != 'C' ) {
                            show = false;
                        }
                    } else if (item.type == 'Crédito de ICMS' || item.type == 'CI') {
                        if (typeof scope.cart.header.selectedAccount.shippingState != 'undefined') {
                            if (scope.cart.header.selectedAccount.shippingState != 'SP' || !JSON.parse(scope.cart.header.selectedAccount.icmsPayer)) {
                                show = false;
                            }
                        } else {
                            show = false;
                        }
                    } else if (item.type == 'Crédito Rural Stoller' || item.type == 'CR') {
                        if (scope.cart.header.selectedAccount.clientType != 'ZB') {
                            show = false;
                        }
                    }
                } else {
                    show = false;
                }
                return (
                    show &&
                    item.currencyOpt == scope.cart.header.currency.value
                );
            });
            return paymentConditionsFilter;
        };

        scope.showAgency = function () {
            if (scope.cart.header.selectedAccount == null) {
                return false;
            }
            return (
                scope.cart.header.selectedAccount.resale > ' ' &&
                scope.cart.header.selectedAccount.clientType == 'ZE'
            );
        };

        scope.floatButtons = {
            options: {
                buttonClass: 'a',
                isOpen: false,
                controlButton: {
                    buttonClass: 'c',
                    opened: {
                        iconPath: '/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#close',
                        label: 'Fechar',
                        callback: scope.openFloatingButton
                    },
                    closed: {
                        iconPath: '/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#threedots_vertical',
                        label: 'Abrir',
                        callback: scope.openFloatingButton
                    }
                },
                closeMethod: scope.openFloatingButton
            },
            buttons: [
                {
                    iconPath: '/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#copy',
                    label: 'Clonar',
                    buttonClass: '',
                    show: [],                    
                    callback: function () {
                        Swal.fire({
                            title: 'Clonar?',
                            text: 'Deseja realmente clonar a Oportunidade ' + scope.oppName + '?',
                            type: 'info',
                            showCancelButton: true,
                            confirmButtonColor: '#3085d6',
                            confirmButtonText: 'Clonar!',
                            cancelButtonText: 'Nãoooo'
                        }).then((result) => {
                            if (result.value) {
                                scope.isLoading = true;
                                scope.$apply();
                                callRemoteAction('OpportunityAppController.cloneOpportunity', scope.oppId, function (resultOpp, event) {
                                    scope.isLoading = false;
                                    if (event.status) {
                                        if (!resultOpp.hasErrors) {
                                            scope.$apply();
                                            Swal.fire({
                                                title: 'Show',
                                                text: 'Deseja abrir a oportunidade ' + resultOpp.data.name + ' que acabou de ser criada?',
                                                type: 'success',
                                                showCancelButton: true,
                                                confirmButtonColor: '#3085d6',
                                                confirmButtonText: 'Abrir!',
                                                cancelButtonText: 'Nãoooo'
                                            }).then((result) => {
                                                if (result.value) {
                                                    sforce.one.navigateToURL('/apex/OpportunityApp?id=' + resultOpp.data.id);  
                                                }
                                            });
                                        } else {
                                            scope.$apply();
                                            Log.fire(resultOpp, {code: '8765'});
                                        }
                                    } else {
                                        scope.$apply();
                                        Log.fire(event, {code: '5678'});
                                    }
                                });
                            }
                        });
                        scope.floatButtons.options.closeMethod();
                    },
                },
                {
                    iconPath: '/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#task',
                    label: 'Reenviar email cliente',
                    buttonClass: '',
                    show: ['Em Aprovação Cliente'],
                    callback: function () {
                        Swal.fire({
                            title: 'Aviso',
                            text: 'Esta ação irá reenviar o email de aprovação para o Cliente/RTV, deseja continuar?',
                            type: 'info',
                            showCancelButton: true,
                            confirmButtonColor: '#3085d6',
                            confirmButtonText: 'Enviar!',
                            cancelButtonText: 'Nãoooo'
                        }).then((result) => {
                            if (result.value) {
                                callRemoteAction('OpportunityAppController.sendEmailClient', scope.oppId, function (resultOpp, event) {
                                    scope.isLoading = false;
                                    if (event.status) {
                                        if (!resultOpp.hasErrors) {
                                            scope.$apply();
                                            Swal.fire({
                                                title: 'Show',
                                                text: 'Email Enviado com sucesso!',
                                                type: 'success',
                                                confirmButtonColor: '#3085d6',
                                                confirmButtonText: 'Ok!'
                                            }).then((result) => {
                                                sforce.one.navigateToSObject(scope.oppId);
                                            });
                                        } else {
                                            scope.$apply();
                                            Log.fire(resultOpp, {code: '6477'});
                                        }
                                    } else {
                                        scope.$apply();
                                        Log.fire(event, {code: '8888'});
                                    }
                                });
                            }
                        });
                        scope.floatButtons.options.closeMethod();
                    },
                },
                {
                    iconPath: '/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#task',
                    label: 'Solicitar aprovação',
                    buttonClass: '',
                    show: ['Iniciado', 'Reprovado Comercial', 'Reprovado Marketing', 'Reprovado Cliente'],                    
                    callback: function () {
                        Swal.fire({
                            title: 'Preparado?',
                            text: 'Deseja enviar a oportunidade ' + scope.oppName + ' para aprovação?',
                            type: 'info',
                            showCancelButton: true,
                            confirmButtonColor: '#3085d6',
                            confirmButtonText: 'Enviar!',
                            cancelButtonText: 'Nãoooo'
                        }).then((result) => {
                            if (result.value) {
                                callRemoteAction('OpportunityAppController.approveOpportunity', scope.oppId, function (resultOpp, event) {
                                    scope.isLoading = false;
                                    if (event.status) {
                                        if (!resultOpp.hasErrors) {
                                            scope.$apply();
                                            Swal.fire({
                                                title: 'Show',
                                                text: 'Sua oportunidade ' + resultOpp.data.name + ' foi enviada para aprovação!',
                                                type: 'success',
                                                confirmButtonColor: '#3085d6',
                                                confirmButtonText: 'Legal!'
                                            }).then((result) => {
                                                sforce.one.navigateToSObject(scope.oppId);
                                            });
                                        } else {
                                            scope.$apply();
                                            Log.fire(resultOpp, {code: '6476'});
                                        }
                                    } else {
                                        scope.$apply();
                                        Log.fire(event, {code: '8878'});
                                    }
                                });
                            }
                        });
                        scope.floatButtons.options.closeMethod();
                    },
                },
                {
                    iconPath: '/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#signpost',
                    label: 'Simular aprovadores',
                    buttonClass: '',
                    show: ['Iniciado', 'Reprovado Comercial', 'Reprovado Marketing', 'Reprovado Cliente'],                    
                    callback: function () {
                        scope.isLoading = true;
                        callRemoteAction('OpportunityAppController.simulateApprovalProcess', scope.oppId, function (resultOpp, event) {
                            scope.isLoading = false;
                            if (event.status) {
                                if (!resultOpp.hasErrors) {
                                    let html = '';
                                    for (const key in resultOpp.data) {
                                        let helpTextsHtml = '';
                                        if (typeof resultOpp.data[key].helpTexts != 'undefined') {
                                            for (let i = 0; i < resultOpp.data[key].helpTexts.length; i++) {
                                                let text = resultOpp.data[key].helpTexts[i];
                                                helpTextsHtml += ''+
                                                    '<small>' + text + '</small>'
                                                ;
                                            }                                            
                                        }
                                        html += ''+
                                            '<li class="slds-progress__item slds-is-completed">   ' +
                                            '    <div class="slds-progress__marker">   ' +
                                            '        <span class="slds-assistive-text">Active</span>   ' +
                                            '    </div>' +
                                            '    <div class="slds-progress__item_content slds-grid">'+
                                            '       Passo ' + key + ', <a href="/' + resultOpp.data[key].approverId + '" target="_blank">' + resultOpp.data[key].approverName + '</a>'+
                                                    helpTextsHtml +
                                            '    </div>' +
                                            '</li> '
                                        ;
                                    }
                                    let msg = {
                                        message: 'Esses são os aprovadores de cada etapa do fluxo de aprovação da oportunidade ' + scope.oppName + '!',
                                        stackStrace: '' +
                                            '<div class="slds-progress slds-progress_vertical">' +
                                            '    <ol class="slds-progress__list">  '+
                                                    html +
                                            '    </ol> '+
                                            '    <div aria-valuemin="0" aria-valuemax="100" aria-valuenow="100" role="progressbar"> '+
                                            '       <span class="slds-assistive-text">Progress: 100%</span>'+
                                            '    </div>'+
                                            '</div>'
                                    };
                                    Log.fire(msg, {
                                        code: null,
                                        open: true,
                                        type: 'success',
                                        title: 'Show',
                                        callback: function (result) {
                                            sforce.one.navigateToSObject(scope.oppId);                                            
                                        }
                                    });
                                    scope.$apply();
                                } else {
                                    scope.$apply();
                                    Log.fire(resultOpp, {code: '6476'});
                                }
                            } else {
                                scope.$apply();
                                Log.fire(event, {code: '8878'});
                            }
                        });
                        scope.floatButtons.options.closeMethod();
                    },
                },
                {
                    iconPath: '/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#edit',
                    label: 'Editar',
                    show: ['Iniciado', 'Reprovado Comercial', 'Reprovado Marketing', 'Reprovado Cliente'],
                    callback: function () {
                        Toast.fire({
                            type: 'success',
                            title: 'Você já pode editar sua oportunidade!'
                        });
                        scope.floatButtons.options.closeMethod();
                        scope.pageView = 'edit';
                    },
                },
                {
                    iconPath: '/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#delete',
                    label: 'Excluir',
                    show: (scope.hasMasterAccess ? ['Iniciado', 'Reprovado Comercial', 'Reprovado Marketing', 'Reprovado Cliente'] : ['Iniciado']),
                    callback: function () {
                        Swal.fire({
                            title: 'Atenção!',
                            text: 'Deseja realmente excluir a Oportunidade ' + scope.oppName + '?',
                            type: 'warning',
                            showCancelButton: true,
                            confirmButtonColor: '#3085d6',
                            confirmButtonText: 'Excluir!',
                            cancelButtonText: 'Nãoooo'
                        }).then((result) => {
                            if (result.value) {
                                callRemoteAction('OpportunityAppController.deleteOpportunity', scope.oppId, function (result, event) {
                                    scope.isLoading = false;
                                    if (event.status) {
                                        if (!result.hasErrors) {
                                            Toast.fire({
                                                type: 'success',
                                                title: result.message
                                            });
                                            var url = new URL(location.href);
                                            var query_string = url.search;
                                            var search_params = new URLSearchParams(query_string);
                                            search_params.delete('id');
                                            url.search = search_params.toString();
                                            var new_url = url.toString();
                                            location = new_url;
                                        } else {
                                            scope.$apply();
                                            Log.fire(result, {code: '6767'});
                                        }
                                    } else {
                                        scope.$apply();
                                        Log.fire(event, {code: '5675'});
                                    }
                                });
                            }
                        });                        
                        scope.floatButtons.options.closeMethod();
                    },
                },
                {
                    iconPath: '/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#download',
                    label: 'Gerar PDF',
                    show: ['Em Aprovação Cliente'],
                    callback: function () {
                        sforce.one.navigateToURL('/apex/GenerateOpportunityPDF?id=' + scope.oppId);
                        scope.floatButtons.options.closeMethod();
                    },
                },
            ]
        };

        scope.floatButtonsFilter = function () {
            let filterButtons = scope.floatButtons;
            if (scope.oppStatus > ' ') {
                filterButtons.buttons = filterButtons.buttons.filter(function (item) {

                    if (item.label == 'Gerar PDF' && scope.isPDFGenerator) {
                        return true;
                    }
                    var cond = item.show.length == 0 || item.show.indexOf(scope.oppStatus) > -1;
                    if (!scope.isCustomerService){
                        return cond;
                    } else {
                        if (item.label == 'Gerar PDF'){
                            return true;
                        }
                        return cond;
                    }
                });
            }
            return filterButtons;
        };

        scope.openFloatingButton = function () {
            scope.floatButtons.options.isOpen = !scope.floatButtons.options.isOpen;
        };

        scope.floatButtons.options.controlButton.opened.callback = scope.openFloatingButton;
        scope.floatButtons.options.controlButton.closed.callback = scope.openFloatingButton;
        scope.floatButtons.options.closeMethod = scope.openFloatingButton;
        
        scope.selectedPayment = null;

    }]);

    shoppingCartApp.config(function ($routeProvider) {
        $routeProvider.
        when('/header', {
            templateUrl: window.URLS.opportunityAppHeader,
            controller: 'HeaderCtrl'
        }).
        when('/productlist', {
            templateUrl: window.URLS.opportunityAppProductList,
            controller: 'ProductCtrl'
        }).
        when('/cart', {
            templateUrl: window.URLS.opportunityAppCart,
            controller: 'CartCtrl'
        }).
        when('/ship', {
            templateUrl: window.URLS.opportunityAppShip,
            controller: 'ShipCtrl'
        }).
        when('/summary', {
            templateUrl: window.URLS.opportunityAppSummary,
            controller: 'SummaryCtrl'
        }).
        otherwise({
            redirectTo: '/header'
        });
    });

    shoppingCartApp.controller('HeaderCtrl', ['$scope', '$http', function (scope, $http) {

        window.scrollTo(0, 0);

        scope.isCustomerService = window.isCustomerService;

        scope.$parent.containerClass = '';
        scope.step.title = (scope.oppId > ' ' ? 'Detalhes da ' + scope.oppName : 'Nova Oportunidade');
        scope.step.actionNextStepText = 'Avançar';
        scope.step.indicator = 1;
        scope.step.nextTitle = 'Próximo: Catálogo';
        scope.step.calcCoords();
        scope.step.actionNextStep = function () {
            if (scope.cart.header.paymentCondition.type == 'V' || scope.cart.header.paymentCondition.type == 'Vendor') {
                if (!scope.cart.header.paymentCondition.prepareVendor) {
                    scope.cart.header.paymentCondition.prepareVendor    = true;
                    scope.cart.header.paymentCondition.valueInfo        = scope.cart.header.paymentCondition.value;
                    scope.cart.header.paymentCondition.value            = 0;                    
                }
            }else {
                scope.cart.header.paymentCondition.valueInfo = scope.cart.header.paymentCondition.value;
            }
            location.href = "#/productlist";
        };
        scope.step.actionBackStep = function () {
            if(scope.oppId > ' '){
                sforce.one.navigateToSObject(scope.oppId);
            } else {
                sforce.one.navigateToURL('/006/o');
            }
        };
        scope.step.showNextStep = function () {
            let validateVendorDate = true;
            if (scope.cart.header.paymentCondition != null) {
                if (scope.cart.header.paymentCondition.type == 'V' || scope.cart.header.paymentCondition.type == 'Vendor') {
                    if (!scope.cart.header.vendorDate) {
                        validateVendorDate = false;
                    }
                }
            }
            let validateCampaign = true;
            if (scope.cart.header.salesClassification != null) {
                if (scope.cart.header.salesClassification.value.indexOf('Campanha') > -1) {
                    if (scope.cart.header.selectedCampaign == null) {
                        validateCampaign = false;
                    }
                }
            }
            let validateShippingAcc = true;
            let validateOrderReason = true;
            if (scope.cart.header.orderType != null) {
                if (scope.cart.header.orderType.value.indexOf('Remanejamento') > -1) {
                    if (scope.cart.header.shipperAccount == null) {
                        validateShippingAcc = false;
                    }
                }
                if (scope.cart.header.orderType.value == 'Bonificação') {
                    if (scope.cart.header.orderReason == null || !scope.cart.header.obsInternal) {
                        validateOrderReason = false;
                    }
                }
            }
            if (scope.cart.header.currency != null) {
                scope.base.currentCurrencyLabel = (scope.cart.header.currency.value == 'BRL' ? 'R$' : 'US$');
            }
            if (scope.cart.header.paymentCondition != null) {
                if (scope.selectedPayment != null) {
                    if (scope.cart.header.paymentCondition.id != scope.selectedPayment.id) {
                        scope.selectedPayment = scope.cart.header.paymentCondition;
                    }                    
                }else {
                    scope.selectedPayment = scope.cart.header.paymentCondition;
                }
            }
            let allCSFieldsValid = true;
            if (scope.hasMasterAccess) {
                if (        scope.cart.header.selectedBusinessPlace == null 
                        || scope.cart.header.selectedFreightType == null 
                        || scope.cart.header.selectedTerritory == null) {
                    allCSFieldsValid = false;
                }
            }

            return (
                    scope.cart.header.selectedAccount       != null
                &&  scope.cart.header.currency              != null
                &&  scope.cart.header.expedition            != null
                &&  scope.cart.header.orderType             != null
                &&  scope.cart.header.salesClassification   != null
                &&  scope.cart.header.paymentCondition      != null
                &&  validateVendorDate
                &&  validateCampaign
                &&  validateShippingAcc
                &&  validateOrderReason
                &&  allCSFieldsValid
            );
        };

        scope.showCalendar = false;

        scope.init = function () {
            scope.updateVendorCalendar();
            
            referenceDate = Calendar.create('wrapper-reference-date', {
                dates: {},
                initDate: formatDateForm(new Date()),
                isOpen: true,
                name: 'reference-date',
                greaterThanInit: false,
                lessThanInit: true,
                weekendAvaliable: true
            }, function (result, name) {
                scope.setReferenceDate(result, name);
            });

            scope.calendarVisibility[referenceDate.name] = false;

        };

        scope.init();

        scope.setDate = function (dt, name) {
            scope.cart.header.vendorDate = dt;
            scope.cart.header.vendorDateFormated = scope.formatScopeDate(dt);
            scope.calendarVisibility[name] = false;
            scope.$apply();
        };
       
        scope.setReferenceDate = function (dt, name) {
            scope.base.priceReferenceDate = dt;
            scope.cart.header.referenceDateFormatted = scope.formatScopeDate(dt);
            scope.calendarVisibility[name] = false;
            scope.campaignFilter.find(a => a.fieldApiName == 'dataVigenciaDe__c').value = formatDateForm(dt);
            scope.campaignFilter.find(a => a.fieldApiName == 'dataVigenciaAte__c').value = formatDateForm(dt);

            callRemoteAction('OpportunityAppController.getRemoteAllPaymentConditions', formatDateForm(dt), function (result, event) {
                console.log(result);
                if (event.status) {
                    if (!result.hasErrors) {
                        scope.base.paymentConditions = result.paymentConditions;
                        scope.base.filteredPaymentConditions = scope.updatePaymentConditions(scope.base.paymentConditions);
                        scope.cart.header.selectedCampaign = null;
                        scope.cart.header.paymentCondition = null;
                        scope.$apply();
                    } else {
                        scope.$apply();
                        Log.fire(result, {code: '5554'});
                    }
                } else {
                        scope.$apply();
                        Log.fire(event, {code: '4554'});
                    }
            });

            scope.$apply();
        };

        scope.openCalendar = function (name) {
            scope.calendarVisibility[name] = !scope.calendarVisibility[name];
        };

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

        scope.showVendorDueDate = function () {
            let show = false;
            if (scope.cart.header.paymentCondition) {
                if (scope.cart.header.paymentCondition.type == 'V' || scope.cart.header.paymentCondition.type == 'Vendor') {
                    show = true;
                } else {
                    scope.cart.header.vendorDate = null;
                    scope.cart.header.vendorDateFormated = '';
                }
            }
            return show;
        };

    }]);

    shoppingCartApp.controller('SectionCtrl', ['$scope', function (scope) {

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

    shoppingCartApp.controller('SectionBonificacaoCtrl', ['$scope', function (scope) {

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

        scope.setReasonOrder = function (item) {
            scope.cart.header.orderReason = item;
            scope.init(false);
        };

    }]);

    shoppingCartApp.controller('ProductCtrl', ['$scope', '$http', function (scope, http) {

        scope.isLoading = true;
        if (scope.cart.header.selectedAccount != null) {
            if (typeof scope.cart.header.targetCultures == 'undefined') {
                scope.cart.header.targetCultures = scope.base.cultures;
            }

            var territory;
            if (scope.cart.header.selectedTerritory != null) {
                territory = Object.assign({}, scope.cart.header.selectedTerritory);
                delete territory['$$hashKey'];
            }
            if (scope.isCustomerService && scope.cart.header.selectedBusinessPlace != null) {
                if (!scope.cart.header.selectedBusinessPlace.hasOwnProperty('id') && scope.cart.header.selectedBusinessPlace.hasOwnProperty('Id')) {
                    scope.cart.header.selectedBusinessPlace.id = scope.cart.header.selectedBusinessPlace.Id;
                }                
            }
            callRemoteAction('OpportunityAppController.getOpportunityAppProductData', {
                accountId:  scope.cart.header.selectedAccount.id,
                receiverId: (scope.cart.header.orderType.value == 'Conta e Ordem' ? (scope.cart.header.receiverAccount != null ? scope.cart.header.receiverAccount.id : scope.cart.header.selectedAccount.id) : scope.cart.header.selectedAccount.id),
                shipmentCondition: scope.cart.header.expedition.value,
                currencyName: scope.cart.header.currency.value,
                cultures: scope.cart.header.targetCultures.map(a => a.id),
                freightType: scope.cart.header.selectedFreightType.value,
                territoryData: territory,
                businessPlaceId: (scope.cart.header.selectedBusinessPlace || {}).id,
                priceReferenceDate: formatDateForm(scope.base.priceReferenceDate)
            }, function (result, event) {
                scope.isLoading = false;
                if (event.status) {
                    if (!result.hasErrors) {
                        if (scope.pageView == 'insert' || scope.pageView == 'edit') {
                            scope.cart.ship.defaultDate     = formatDateForm(result.data.deliveryData.minimumDate);
                            scope.base.unavailableDates     = result.data.deliveryData.unavailableDates;
                            scope.base.territoryData        = result.data.territoryData;
                            scope.base.internalDeadlineDays = result.data.deliveryData.internalDeadlineDays;
                            scope.base.itineraryDays        = result.data.deliveryData.itineraryDays;
                            scope.base.deliveryData         = result.data.deliveryData;
                            scope.base.priceAppData         = result.data.priceAppData;
                            scope.base.productsRA           = result.data.productsRA;
                            if (result.data.productsData.length > 0) {
                                let arrHelper = [];
                                if (scope.base.arrProducts.length > 0) {
                                    arrHelper = scope.base.arrProducts.slice();
                                }
                                scope.base.arrProducts = result.data.productsData;
                                scope.base.arrProducts.forEach(function (item) {
                                    item.priceListRef = item.priceList;
                                });
                                arrHelper.forEach(function (item, index) {
                                    let currProduct = scope.base.arrProducts.find(p => p.id == item.id);
                                    if (typeof currProduct != 'undefined') {
                                        currProduct.id                        = item.id;
                                        currProduct.itemId                    = item.itemId;
                                        currProduct.customerTypeDiscount      = item.customerTypeDiscount;
                                        currProduct.customerTypeDiscountValue = item.customerTypeDiscountValue;
                                        currProduct.freightPercentage         = item.freightPercentage;
                                        currProduct.freightValue              = item.freightValue;
                                        currProduct.internalDeadlineDays      = item.internalDeadlineDays;
                                        currProduct.itineraryDays             = item.itineraryDays;
                                        currProduct.maxDiscount               = item.maxDiscount;
                                        currProduct.minimumDiscount           = item.minimumDiscount;
                                        currProduct.multiplicity              = item.multiplicity;
                                        currProduct.name                      = item.name;
                                        currProduct.pbEntry                   = item.pbEntry;
                                        currProduct.recommendedDiscount       = item.recommendedDiscount;
                                        currProduct.sku                       = item.sku;
                                        currProduct.shippingTableId           = item.shippingTableId;
                                        currProduct.discountPolicyId          = item.discountPolicyId;
                                        currProduct.priceEntryId              = item.priceEntryId;
                                        currProduct.customerTypeDiscountId    = item.customerTypeDiscountId;
                                        currProduct.culture                   = item.hasOwnProperty('culture')  ? item.culture  : null;
                                        currProduct.discount                  = item.hasOwnProperty('discount') ? item.discount : 0;
                                        currProduct.quantity                  = item.hasOwnProperty('quantity') ? item.quantity : 0;
                                        currProduct.receiver                  = item.hasOwnProperty('receiver') ? item.receiver : null;
                                        currProduct.inCart                    = item.inCart;
                                        currProduct.ipiPercentage             = item.ipiPercentage;

                                        if (item.inCart) {
                                            let productInCart = scope.cart.products.find(p => p.id == item.id);
                                            if (typeof productInCart != 'undefined') {
                                                let interestValue = scope.cart.header.paymentCondition.value / 100;
                                                let increaseInterest = currProduct.priceList * interestValue;
                                                let salesPriceWithInterestBase = currProduct.priceList + increaseInterest;
                                                let needDelete = false;
                                                let needCalc = false;
                                                if (productInCart.hasOwnProperty('salesPriceWithInterestBase')) {
                                                    let salesPriceWithInterestBaseBRLUSD = (scope.cart.header.currency.value == 'USD' ? productInCart.salesPriceWithInterestDolar : productInCart.salesPriceWithInterest);
                                                    salesPriceWithInterestBaseBRLUSD = Math.floor(salesPriceWithInterestBaseBRLUSD * (1 -(productInCart.discount/100)));
                                                    if (salesPriceWithInterestBase < salesPriceWithInterestBaseBRLUSD) {
                                                        needDelete = true;
                                                    } else {
                                                        needCalc = true;
                                                    }
                                                }
                                                if (needCalc) {
                                                    var c = (productInCart.salesPrice / productInCart.priceList);
                                                    var diff = 1 - c;
                                                    if(productInCart.salesPrice > productInCart.priceList) {
                                                        diff = Math.abs(diff * 100);
                                                    }
                                                    else {
                                                        diff = -1 * Math.abs(diff * 100);
                                                    }

                                                    productInCart.discount = diff;
                                                    if (scope.cart.header.currency.value == 'USD') {
                                                        productInCart.priceListDolar = currProduct.priceList;
                                                        delete productInCart.priceList;
                                                        delete productInCart.salesPrice;
                                                        delete productInCart.salesPriceWithInterest;
                                                        delete productInCart.salesPriceWithInterestBase;
                                                    }else {
                                                        productInCart.priceList = currProduct.priceList;
                                                        delete productInCart.priceListDolar;
                                                        delete productInCart.salesPriceDolar;
                                                        delete productInCart.salesPriceWithInterestDolar;
                                                        delete productInCart.salesPriceWithInterestDolarBase;
                                                    }
                                                }
                                                if (needDelete) {
                                                    delete productInCart.discount;
                                                    delete productInCart.salesPrice;
                                                    delete productInCart.salesPriceDolar;
                                                    delete productInCart.salesPriceWithInterest;
                                                    delete productInCart.salesPriceWithInterestDolar;
                                                    delete productInCart.salesPriceWithInterestBase;
                                                    delete productInCart.salesPriceWithInterestDolarBase;
                                                    delete productInCart.quantityLiter;
                                                    delete productInCart.totalValue;
                                                    delete productInCart.priceList;
                                                    delete productInCart.priceListDolar;
                                                    delete productInCart.pricePerLiter;
                                                }
                                                scope.$apply();
                                            }
                                        }                                  
                                    }
                                });
                            } else {
                                scope.base.arrProducts = [];
                            }
                            if (scope.pageView != 'read') {
                                // mudar, deixar igual a programação de entrega
                                // sinalizando data invalida
                                let clear = false;
                                for (let i = 0; i < scope.cart.ship.dates.length; i++) {
                                    if (scope.cart.ship.dates[i] < scope.cart.ship.defaultDate) {
                                        clear = true;
                                        break;
                                    }
                                }
                                if (clear) {
                                    scope.cart.ship.currentDate = null;
                                    scope.cart.ship.dates       = [];
                                    scope.cart.ship.products    = [];
                                    scope.cart.products.forEach(function (item, index) {
                                        scope.cart.products[index].balance = scope.cart.products[index].quantity;
                                    });
                                }
                                scope.cart.products.forEach(function (item, index) {
                                    let currProduct = scope.base.arrProducts.find(p => p.id == item.id);
                                    if (typeof currProduct != 'undefined') {
                                        if (scope.cart.products[index].priceList != currProduct.priceList) {
                                            scope.cart.products.splice(index, 1);
                                        }
                                    }
                                });
                            }
                        }else {
                            scope.base.arrProducts.forEach(function (item) {
                                if (!item.hasOwnProperty('liter')) {
                                    item.liter = item.quantityLiter / item.quantity;
                                }
                            });
                        }
                        scope.$apply();
                    } else {
                        scope.base.arrProducts = [];
                        scope.$apply();
                        Log.fire(result, {code: '6554'});
                    }
                } else {
                    scope.$apply();
                    Log.fire(event, {code: '4644'});
                }
                scope.$apply();
            });
        } else {
            scope.isLoading = false;
            scope.$apply();
        }

        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.step.title = 'Catálogo';
        scope.step.actionNextStepText = 'Avançar';
        scope.step.indicator = 2;
        scope.step.nextTitle = 'Próximo: Quantidade e Preço';
        scope.step.actionNextStep = function () {
            var arr = scope.base.arrProducts.filter(function (item) {
                return item.inCart;
            });
            for (let i = 0; i < arr.length; i++) {
                var haveItem = scope.cart.products.find(function (item) {
                    return item.id == arr[i].id;
                });
                var item = haveItem;
                if (!haveItem) {
                    item = Object.assign({}, arr[i]);
                    item.priceList = item.priceList;
                }
                if (!item.hasOwnProperty('quantity')) {
                    item.quantity = 0;
                }
                if (!item.hasOwnProperty('quantityLiter')) {
                    item.quantityLiter = 0;
                }
                if (!item.hasOwnProperty('totalValue')) {
                    item.totalValue = 0;
                }
                if (!item.hasOwnProperty('priceList')) {
                    item.priceList = item.priceListDolar;
                    if (scope.base.currentCurrencyLabel == 'R$') {
                        item.priceListDolar = item.priceListDolar / scope.base.dolar;
                    } else {
                        item.priceList = item.priceListDolar * scope.base.dolar;
                    }
                }
                if (!item.hasOwnProperty('priceListDolar')) {
                    item.priceListDolar = item.priceList;
                    if (scope.base.currentCurrencyLabel == 'R$') {
                        item.priceListDolar = item.priceListDolar / scope.base.dolar;
                    } else {
                        item.priceList = item.priceListDolar * scope.base.dolar;
                    }
                }
                if (!item.hasOwnProperty('pricePerLiter')) {
                    item.pricePerLiter = 0;
                }
                if (!item.hasOwnProperty('salesPrice')) {
                    item.salesPrice = item.priceList;
                }
                if (!item.hasOwnProperty('salesPriceDolar')) {
                    item.salesPriceDolar = item.priceListDolar;
                }
                if (!item.hasOwnProperty('salesPriceWithInterest')) {
                    var interestValue = scope.cart.header.paymentCondition.value / 100;
                    var increaseInterest = item.salesPrice * interestValue;
                    item.salesPriceWithInterestBase = item.priceList + increaseInterest;
                    item.salesPriceWithInterest = item.salesPrice + increaseInterest;
                }
                if (!item.hasOwnProperty('salesPriceWithInterestDolar')) {
                    var interestValue = scope.cart.header.paymentCondition.value / 100;
                    var increaseInterest = item.salesPriceDolar * interestValue;
                    item.salesPriceWithInterestDolarBase = item.priceListDolar + increaseInterest;
                    item.salesPriceWithInterestDolar = item.salesPriceDolar + increaseInterest;
                }
                if (!item.hasOwnProperty('discount')) {
                    item.discount = 0;
                }
                if (!item.hasOwnProperty('culture')) {
                    item.culture = scope.cart.header.culture;
                }
                if (!item.hasOwnProperty('receiverAccount')) {
                    item.receiverAccount = [];
                    item.receiverAccount.push((scope.cart.header.receiverAccount != null ? scope.cart.header.receiverAccount : {
                        id: ''
                    }));
                }
                if (!haveItem) {
                    scope.cart.products.push(item);
                }
            }
            let arrHelper = [];
            scope.cart.products.forEach(function (item, index) {
                var haveItem = arr.find(function (product) {
                    return item.id == product.id;
                });
                if (haveItem) {
                    arrHelper.push(item);
                }
            });
            scope.cart.products = arrHelper;
            if (scope.cart.products.length > 0) {
                if (scope.cart.ship.dates.length > 0) {
                    scope.cart.ship.currentDate = scope.cart.ship.dates[0];
                }
                location.href = "#/cart";
            }
        };
        scope.step.actionBackStep = function () {
            location.href = "#/header";
        };
        scope.step.calcCoords();
        scope.step.showNextStep = function () {
            var arr = [];
            if (typeof scope.base.arrProducts != 'undefined') {
                arr = scope.base.arrProducts.filter(function (item) {
                    return item.inCart;
                });
            }
            return (arr.length > 0);
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

        scope.checkDiscount = function (event, product) {
            debugger;
            if (event.keyCode >= 96 && event.keyCode <=105){
                debugger;

            }
        }
        scope.discountChange = function (p) {
            if (p.discount < 0 || p.discount == undefined) {
                p.discount = 0;
            }
            p.salesPrice = p.priceList - (p.priceList * (p.discount / 100));
            p.salesPriceWithInterest = roundTo(p.salesPrice + (p.salesPrice * ((scope.cart.header.paymentCondition.value / 100))), 2);
            p.salesPrice = roundTo(p.salesPrice, 2);
        };

    }]);

    shoppingCartApp.controller('CartCtrl', ['$scope', '$http', function (scope, http) {
        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.step.title = 'Quantidade e Preço';
        scope.step.actionNextStepText = 'Avançar';
        scope.step.indicator = 3;
        scope.step.nextTitle = 'Próximo: Datas de Entrega';
        scope.step.calcCoords();
        scope.step.actionNextStep = function () {
            let allQuantity = 0;
            let allHaveCulture = true;
            scope.cart.products.forEach(function (item, index) {
                allQuantity += item.quantity;
                if (item.culture == null) {
                    allHaveCulture = false;
                    return false;
                }
            });
            if (allQuantity > 0 && allHaveCulture) {
                location.href = "#/ship";
            }
        };
        scope.step.actionBackStep = function () {
            location.href = "#/productlist";
        };
        scope.step.showNextStep = function () {
            let allQuantity = 0;
            let allOk = true;
            let multiplicityOk = true;
            scope.cart.products.forEach(function (item, index) {
                if (item.quantity % item.multiplicity > 0) {
                    multiplicityOk = false;
                }
                allQuantity += item.quantity;
                /*let priceOk = (item.salesPriceWithInterest > item.salesPriceWithInterestBase);
                if (scope.cart.header.currency.value == 'USD') {
                    priceOk = (item.salesPriceWithInterestDolar > item.salesPriceWithInterestDolarBase);
                }*/
                if (item.culture == null /*|| priceOk */|| item.quantity <= 0) {
                    allOk = false;
                    return false;
                }
            });
            return (allQuantity > 0 && allOk && multiplicityOk);
        };

        scope.totalItem = function (p, withInterest) {
            if (typeof withInterest == 'undefined') {
                withInterest = true;
            }
            p.totalValue = p.quantity * p.salesPrice;
            p.totalValueWithInterest = p.quantity * p.salesPriceWithInterest;
            p.salesPrice = p.salesPrice;
            p.salesPriceWithInterest = p.salesPriceWithInterest;
            if (withInterest) {
                return scope.formatPrice(p.totalValueWithInterest);
            }
            return scope.formatPrice(p.totalValue);
        };

        scope.totalItemDolar = function (p, withInterest) {
            if (typeof withInterest == 'undefined') {
                withInterest = true;
            }
            p.totalValueDolar = p.salesPriceDolar * p.quantity;
            p.totalValueWithInterestDolar = p.salesPriceWithInterestDolar * p.quantity;
            p.salesPriceDolar = p.salesPriceDolar;
            p.salesPriceWithInterestDolar = p.salesPriceWithInterestDolar;
            if (withInterest) {
                return scope.formatPrice(p.totalValueWithInterestDolar);
            }
            return scope.formatPrice(p.totalValueDolar);
        };

        scope.formatPrice = function (price) {
            return formatMonetary(price, 2);
        };

        scope.increment = function (p) {
            let productInCart = scope.cart.products.find(function (item) {
                return p.id == item.id;
            });
            p.quantity += (productInCart.multiplicity > 0 ? productInCart.multiplicity : 1);
            return p.quantity;
        };

        scope.decrement = function (p) {
            let productInCart = scope.cart.products.find(function (item) {
                return p.id == item.id;
            });
            p.quantity -= (productInCart.multiplicity > 0 ? productInCart.multiplicity : 1);
            if (p.quantity < 0) {
                p.quantity = 0;
            }
            return p.quantity;
        };
        scope.quantityChange = function (p) {
            if (!p.quantity){
                p.quantity = 0;
            }
            if (scope.controlTime.hasOwnProperty(p.id)) {
                clearTimeout(scope.controlTime[p.id]);
            }
            var value = p.quantity % p.multiplicity;
            if (value > 0) {
                scope.controlTime[p.id] = setTimeout(function () {
                    if (value >= p.multiplicity / 2) {
                        p.quantity += p.multiplicity - value;
                    } else {
                        p.quantity -= value;
                    }
                    scope.$apply();
                }, 1000);
            }
            /* else {
                scope.calcBalance(p);
            }*/
        };

        scope.incrementDiscount = function (p) {
            p.discount -= 1;
            p.discount = parseFloat(p.discount.toFixed(2));
            if (p.discount < -100) {
                p.discount = -100;
            }
            scope.discountChange(p);
            return p.discount;
        };
        
        scope.incrementAddition = function (p) {
            p.discount += 1;
            p.discount = parseFloat(p.discount.toFixed(2));
            if (p.discount > 100) {
                p.discount = 100;
            }
            scope.discountChange(p);
            return p.discount;
        };

        scope.discountChange = function (p) {
            if (p.discount == undefined) {
                p.discount = 0;
            }
            p.discount = parseFloat(p.discount.toFixed(2));

            var percent = (p.discount / 100);
            var discountValue = 0;
            var interestValue = scope.cart.header.paymentCondition.value / 100;
            var salesPercent = p.salesPriceDolar * (interestValue);

            if (scope.cart.header.currency.value == 'USD') {
                discountValue = p.priceListDolar * percent;
                p.salesPriceDolar = p.priceListDolar + discountValue;
                p.salesPriceDolar = p.salesPriceDolar;
                salesPercent = p.salesPriceDolar * (interestValue);
                p.salesPriceWithInterestDolar = p.salesPriceDolar + salesPercent;
                p.salesPriceWithInterestDolar = parseFloat(p.salesPriceWithInterestDolar.toFixed(2));
                
                p.salesPrice             = p.salesPriceDolar * scope.base.dolar;
                p.salesPriceWithInterest = p.salesPriceWithInterestDolar * scope.base.dolar;
                p.salesPriceWithInterest = parseFloat(p.salesPriceWithInterest.toFixed(2));
                
            } else {
                discountValue = p.priceList * percent;
                p.salesPrice = p.priceList + discountValue;
                p.salesPrice = p.salesPrice;
                salesPercent = p.salesPrice * (interestValue);
                p.salesPriceWithInterest = p.salesPrice + salesPercent;
                p.salesPriceWithInterest = parseFloat(p.salesPriceWithInterest.toFixed(2));
                
                p.salesPriceDolar = p.salesPrice / scope.base.dolar;
                p.salesPriceWithInterestDolar = p.salesPriceWithInterest / scope.base.dolar;
                p.salesPriceWithInterestDolar = parseFloat(p.salesPriceWithInterestDolar.toFixed(2));
            }

        };

        scope.salesPriceChange = function (p, calcInterest) {
            if (typeof calcInterest == 'undefined') {
                calcInterest = true;
            }
            if (p.salesPrice > 0) {
                var c = (p.salesPrice / p.priceList);
                c = c;
                var diff = 1 - c;
                diff = Math.abs(diff * 100);
                p.discount = parseFloat((p.salesPrice <= p.priceList ? diff * -1 : diff).toFixed(2));
            }else {
                p.salesPrice = p.priceList;
                p.discount = 0;
            }
            if (calcInterest) {
                var interestValue = scope.cart.header.paymentCondition.value / 100;
                var salesPercent = p.salesPrice * (interestValue);
                p.salesPriceWithInterest = p.salesPrice + salesPercent;
            }
            p.salesPrice = p.salesPrice;
        };

        scope.salesPriceWithInterestChange = function (p) {
            var interestValue   = scope.cart.header.paymentCondition.value / 100;
            if (p.salesPriceWithInterest){
                p.salesPrice        = p.salesPriceWithInterest / (1 + interestValue);
            }else{
                p.salesPriceWithInterest = 0;
                p.discount = -100;
            }
                
            p.salesPrice        = p.salesPrice;

            scope.salesPriceChange(p, false);

            if (p.salesPriceWithInterest){
                p.salesPriceWithInterest        = p.salesPriceWithInterest;
                p.salesPriceWithInterestDolar   = p.salesPriceWithInterest / scope.base.dolar;
            }
            p.salesPriceDolar               = p.salesPrice / scope.base.dolar;
        };

        scope.salesPriceWithInterestDolarChange = function (p) {
            var interestValue               = scope.cart.header.paymentCondition.value / 100;
            p.salesPriceWithInterestDolar   = p.salesPriceWithInterestDolar;
            p.salesPriceDolar               = p.salesPriceWithInterestDolar / (1 + interestValue);
            p.salesPrice = p.salesPriceDolar * scope.base.dolar;
            p.salesPrice = p.salesPrice;
            scope.salesPriceChange(p, true);
        };

        scope.calcQuantityLiter = function (p) {
            p.quantityLiter = p.quantity * p.liter;
            return p.quantityLiter;
        };

        scope.calcPricePerLiter = function (p, dolar) {
            if (p.quantityLiter > 0) {
                p.pricePerLiter = (dolar ? p.totalValueWithInterestDolar : p.totalValueWithInterest) / p.quantityLiter;
            } else {
                p.pricePerLiter = 0;
            }
            return scope.formatPrice(p.pricePerLiter);
        };

        scope.calcTotalCartValue = function () {
            scope.cart.total = scope.cart.products.reduce(function (sum, num) {
                return sum + num.totalValue;
            }, 0);
            scope.cart.totalInterest = scope.cart.products.reduce(function (sum, num) {
                return sum + num.totalValueWithInterest;
            }, 0);
            return scope.formatPrice(scope.cart.totalInterest);
        };

        scope.calcTotalCartValueDolar = function () {
            scope.cart.totalDolar = scope.cart.total / scope.base.dolar;
            scope.cart.totalDolarInterest = scope.cart.totalInterest / scope.base.dolar;
            return scope.formatPrice(scope.cart.totalDolarInterest);
        };

        scope.getPtax = function () {
            return scope.formatPrice(scope.base.dolar);
        };

        scope.applyCultureForAll = function () {
            scope.cart.products.forEach(function (item, index) {
                if (item.cultureIds.includes(scope.cart.header.culture.id)) {
                    item.culture = scope.cart.header.culture;
                }
            });
        };

        scope.getProductCultures = function (product) {
            return scope.cart.header.targetCultures.filter(culture => product.cultureIds.includes(culture.id));
        };

        scope.init = function () {
            scope.cart.products.forEach(function (item) {
                scope.discountChange(item);
            });
        };

    }]).directive('format', ['$filter', function ($filter) {
        return {
            require: '?ngModel',
            link: function (scope, elem, attrs, ctrl) {
                if (!ctrl) return;

                ctrl.$formatters.unshift(function (a) {
                    return roundTo(ctrl.$modelValue, 2);
                });

                elem.bind('blur', function (event) {
                    elem.val(roundTo(parseFloat(elem.val()), 2));
                });
            }
        };
    }]);;

    shoppingCartApp.controller('ShipCtrl', ['$scope', '$http', function (scope, http) {
        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.calendarVisibility = {};
        scope.shippingCalendar = void 0;
        scope.step.title = 'Datas de Entrega';
        scope.step.actionNextStepText = 'Avançar';
        scope.step.indicator = 4;
        scope.step.nextTitle = 'Próximo: Resumo e confirmação';
        scope.step.calcCoords();
        scope.step.actionNextStep = function () {
            location.href = "#/summary";
        };
        scope.step.actionBackStep = function () {
            location.href = "#/cart";
        };
        scope.step.showNextStep = function () {
            var allBalance = scope.cart.products.reduce(function (sum, num) {
                return sum + num.balance
            }, 0);
            let multiplicityOk = true;
            scope.cart.products.forEach(function (item, index) {
                if (item.quantity % item.multiplicity > 0) {
                    multiplicityOk = false;
                }
            });
            var itemsConfirmedWhithoutReceiver = [];
            if (scope.cart.header.orderType.value == 'Conta e Ordem') {
                itemsConfirmedWhithoutReceiver = scope.cart.ship.products.filter(function (item) {
                    return (item.confirmed && item.receiverAccount == null);
                });
            }
            return (allBalance == 0 && itemsConfirmedWhithoutReceiver.length == 0 && multiplicityOk);
        };

        scope.showCalendar = false;
        scope.showMoreDates = true;

        scope.validateConfirmedItem = function (item) {
            if (scope.cart.header.selectedAccount.clientType == 'ZE' && scope.base.productsRA.indexOf(item.id) > -1 && item.confirmed) {
                Swal.fire({
                    type: 'warning',
                    title: 'Atenção',
                    html: 'O item <strong>' + item.name + '</strong> necessita de RA. Favor providenciar o(s) documento(s) para liberação do faturamento.'
                });
            }
        };

        scope.isValidDate = function (item) {
            if (typeof item.billingDate == 'undefined') {
                item.billingDate = formatDateForm(getBusinessDate(item.date, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false));
            }
            let confirmationDeadlineDate = new Date(item.billingDate);
            confirmationDeadlineDate.setDate(confirmationDeadlineDate.getDate() - scope.base.confirmationDeadlineDays);
            console.log(confirmationDeadlineDate);
            console.log(new Date());
            console.log(new Date(item.billingDate));
            console.log('---');
            if (isEqualOrGreaterThan(item.date, scope.cart.ship.defaultDate) && isDateInRange(new Date(), confirmationDeadlineDate, item.billingDate)) {
                return true;
            }
            item.confirmed = false;
            return false;
        };

        scope.isBlockedAcc = function (item) {
            return scope.cart.header.orderType.value == 'Bonificação' ? true : !(scope.cart.header.selectedAccount ? scope.cart.header.selectedAccount.block : scope.cart.header.receiver.block);
        };

        scope.isValidAcc = function (item) {
            return !(scope.cart.header.selectedAccount ? scope.cart.header.selectedAccount.block : scope.cart.header.receiver.block);
        };

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

        scope.currentDate = scope.cart.ship.currentDate;
        if (!scope.currentDate) {
            if (scope.cart.ship.dates.length > 0) {
                scope.currentDate = scope.cart.ship.dates[0].date;
            } else {
                scope.currentDate = scope.cart.ship.defaultDate;
                scope.cart.ship.dates.push(scope.currentDate);
            }
        }
        scope.oldDate = scope.currentDate;
        scope.validateShowMoreDate = function () {
            if (scope.cart.ship.dates.indexOf(scope.currentDate) < 0) {
                if (scope.cart.ship.dates.length > 0) {
                    scope.currentDate = scope.cart.ship.dates[0];
                } else {
                    scope.currentDate = scope.cart.ship.defaultDate;
                }
            }
            var allBalance = scope.cart.products.reduce(function (sum, num) {
                if (num.hasOwnProperty('balance')) {
                    return sum + num.balance;
                }
                return sum + 0;
            }, 0);
            if (allBalance <= 0) {
                scope.showMoreDates = false;
                return false;
            }
            if (!scope.hasMasterAccess && scope.cart.ship.dates.length > scope.base.deliveryQuantityLimit) {
                scope.showMoreDates = false;
            } else {
                scope.showMoreDates = true;
            }
        };

        scope.inspectorShip = function () {
            let arrHelper = [];
            scope.cart.ship.products.forEach(function (item, index) {
                let push = true;
                let productInCart = scope.cart.products.find(function (product) {
                    return product.id == item.id;
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
            scope.cart.ship.products = arrHelper;
            arrHelper = [];
            scope.cart.ship.dates.forEach(function (item, index) {
                let product = scope.cart.ship.products.find(function (p) {
                    return p.date == item;
                });
                if (typeof product != 'undefined' && arrHelper.indexOf(item) < 0) {
                    arrHelper.push(item);
                }
            });
            scope.cart.ship.dates = arrHelper;
            scope.validateShowMoreDate();
        };

        scope.prepareDate = function (dt, cut, name) {
            if (scope.oldDate == dt && cut) {
                scope.calendarVisibility[name] = false;
                return false;
            }
            scope.cart.ship.currentDate = scope.currentDate = dt;
            if (scope.cart.ship.dates.indexOf(dt) < 0) {
                scope.cart.ship.dates.push(dt);
            }
            var productsInAllDates = scope.cart.ship.products.filter(function (product) {
                return scope.cart.products.find(function (item) {
                    return product.id == item.id;
                });
            });
            var productsDate = productsInAllDates.filter(function (item) {
                return item.date == dt;
            });
            if (cut) {
                var productsOldDate = productsInAllDates.filter(function (item) {
                    return item.date == scope.oldDate;
                });
                productsOldDate.forEach(function (product, productIndex) {
                    let currentProduct = productsDate.find(function (item) {
                        let receiverItem = item.receiverAccount;
                        let receiverProduct = product.receiverAccount;
                        if (receiverItem == null) {
                            receiverItem = {
                                id: ''
                            };
                        }
                        if (receiverProduct == null) {
                            receiverProduct = {
                                id: ''
                            };
                        }
                        return (
                            product.id == item.id &&
                            receiverProduct.id == receiverItem.id
                        );
                    });
                    if (!currentProduct) {
                        product.date = dt;
                        product.billingDate = formatDateForm(getBusinessDate(dt, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false));
                    } else {
                        currentProduct.quantity += product.quantity;
                        product.quantity = 0;
                    }
                });
            } else {
                scope.cart.products.forEach(function (product, index) {
                    product.receiverAccount.forEach(function (receiver, receiverIndex) {
                        let currentProduct = productsDate.find(function (item) {
                            let receiverItem = item.receiverAccount;
                            let receiverProduct = receiver;
                            if (receiverItem == null) {
                                receiverItem = {
                                    id: ''
                                };
                            }
                            if (receiverProduct == null) {
                                receiverProduct = {
                                    id: ''
                                };
                            }
                            return (
                                product.id == item.id &&
                                receiverProduct.id == receiverItem.id
                            );
                        });
                        if (!currentProduct) {
                            if (product.quantity > 0 && product.balance > 0) {
                                currentProduct = {
                                    id: product.id,
                                    name: product.name,
                                    orderNumber: scope.cart.header.orderNumber,
                                    date: dt,
                                    billingDate: formatDateForm(getBusinessDate(dt, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false)),
                                    quantity: product.balance,
                                    receiverAccount: scope.cart.header.receiverAccount,
                                    confirmed: false
                                };
                                scope.cart.ship.products.unshift(currentProduct);
                                product.balance = 0;
                            }
                        }
                    });
                });
            }
            scope.inspectorShip();
            scope.calendarVisibility[name] = false;
        };

        scope.calcBalance = function (p) {
            let productInCart = scope.cart.products.find(function (item) {
                return item.id == p.id;
            });
            let arr = scope.cart.ship.products.filter(function (item) {
                return item.id == p.id;
            });

            let allQuantity = arr.reduce(function (sum, num) {
                return sum + num.quantity;
            }, 0);
            if (allQuantity > productInCart.quantity) {
                let newBalance = productInCart.quantity;
                for (let index = (scope.cart.ship.products.length - 1); index >= 0; index--) {
                    const product = scope.cart.ship.products[index];
                    if (product.id == productInCart.id) {
                        if (newBalance > 0) {
                            if (product.quantity <= newBalance) {
                                newBalance -= product.quantity;
                            } else {
                                scope.cart.ship.products[index].quantity = newBalance;
                            }
                        } else {
                            scope.cart.ship.products.splice(index, 1);
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
            scope.cart.products.forEach(function (item, index) {
                if (!item.hasOwnProperty('balance') && item.quantity > 0) {
                    item.balance = item.quantity;
                }
            });
            if (scope.pageView != 'read') {
                scope.prepareDate(scope.currentDate, false);
            }
            scope.shippingCalendar = Calendar.create('shipping-calendar', {
                dates: {},
                initDate: scope.cart.ship.defaultDate,
                isOpen: true,
                name: 'shipping-calendar',
                greaterThanInit: true,
                weekendAvaliable: false,
                unavailableDates: scope.base.unavailableDates
            }, function (result, name) {
                scope.setDate(result, name);
            });
        };

        scope.init();

        scope.setNewReceiver = function (product) {
            let productInCart = scope.cart.products.find(function (item) {
                return item.id == product.id;
            });
            let currentProduct = {
                id: product.id,
                name: product.name,
                orderNumber: scope.cart.header.orderNumber,
                date: scope.currentDate,
                billingDate: formatDateForm(getBusinessDate(scope.cart.ship.currentDate, scope.base.deliveryData.itineraryDays, scope.base.deliveryData.unavailableDates, false)),
                quantity: productInCart.balance,
                receiverAccount: null,
                confirmed: false
            };
            scope.cart.ship.products.unshift(currentProduct);
            productInCart.balance = 0;
        };

        scope.showNewReceiver = function (p) {
            let productInCart = scope.cart.products.find(function (item) {
                return item.id == p.id;
            });
            let arr = scope.cart.ship.products.filter(function (item) {
                return item.id == p.id;
            });
            let haveItemWithoutReceiver = arr.filter(function (item) {
                return item.receiverAccount == null
            });
            return productInCart.balance > 0 &&
                scope.cart.header.orderType.value == 'Conta e Ordem' &&
                (haveItemWithoutReceiver.length == 0);
        }

        scope.setDate = function (dt, name) {
            let cut = (scope.oldDate > ' ');
            scope.oldDate = scope.currentDate;
            scope.shippingCalendar.selected = [];
            scope.prepareDate(dt, cut, name);
            scope.$apply();
        };

        scope.openCalendar = function (name) {
            if (scope.oldDate == '') {
                scope.calendarVisibility[name] = !scope.calendarVisibility[name];
            } else {
                scope.calendarVisibility[name] = true;
                scope.oldDate = '';
            }
            scope.shippingCalendar.selected = [];
        };

        scope.openSelectedDate = function (dt, name) {
            if (scope.currentDate == dt) {
                if (scope.pageView == 'read') {
                    return false;
                }
                scope.calendarVisibility[name] = !scope.calendarVisibility[name];
            } else {
                scope.currentDate = dt;
                scope.calendarVisibility[name] = false;
            }
            scope.shippingCalendar.selected = [dt];
        };
        scope.increment = function (p) {
            scope.quantityChange(p, true, true);
        };

        scope.decrement = function (p) {
            scope.quantityChange(p, true, false);
        };

        scope.quantityChange = function (p, helper, plus) {
            if (!p.quantity) {
                p.quantity = 0;
            }
            if (scope.controlTime.hasOwnProperty(p.id)) {
                clearTimeout(scope.controlTime[p.id]);
            }
            let productInCart = scope.cart.products.find(function (item) {
                return item.id == p.id;
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
                    if (value >= 5) {
                        p.quantity += productInCart.multiplicity - value;
                    }else {
                        p.quantity -= value;
                    }
                    scope.$apply();
                }, 1000);
            }else {
                scope.calcBalance(p);
            }
        };

    }]);

    shoppingCartApp.controller('SummaryCtrl', ['$scope', '$http', function (scope, http) {
        window.scrollTo(0, 0);
        scope.step.title = 'Resumo e confirmação';
        scope.step.actionNextStepText = 'Confirmar';
        scope.step.indicator = 5;
        scope.step.nextTitle = '\u00A0';
        scope.step.calcCoords();
        scope.step.actionNextStep = function () {
            if (scope.disableButton) return;

            scope.isLoading = true;
            scope.disableButton = true;
            
            var products = [];
            
            let allCultres = [];
            scope.cart.ship.products.forEach(function (item, index) {
                let productInCart = scope.cart.products.find(function (product) {
                    return item.id == product.id;
                });

                let customerTypeDiscountValue       = 0;
                let customerTypeDiscountValueDolar  = 0;
                let subTotal                        = productInCart.priceFromTable;

                if (typeof scope.base.priceAppData.customerTypeData != 'undefined') {
                    if (scope.base.priceAppData.customerTypeData != null) {
                        let priceFromTable      = productInCart.priceFromTable;
                        let priceFromTableUSD   = productInCart.priceFromTable;
                        if (scope.cart.header.currency.value == 'USD') {
                            priceFromTable = priceFromTableUSD * scope.base.dolar;
                        }else {
                            priceFromTableUSD = priceFromTable / scope.base.dolar;
                        }
                        customerTypeDiscountValue       = productInCart.priceFromTable * (scope.base.priceAppData.customerTypeData.discount / 100);
                        customerTypeDiscountValueDolar  = priceFromTableUSD * (scope.base.priceAppData.customerTypeData.discount / 100);
                        subTotal                        -= customerTypeDiscountValue;
                    }                    
                }
                
                productInCart.priceListDolar                = productInCart.priceList / scope.base.dolar;
                productInCart.salesPriceDolar               = productInCart.salesPrice / scope.base.dolar;
                productInCart.salesPriceWithInterestDolar   = productInCart.salesPriceWithInterest / scope.base.dolar;
                let realDiscount = 0
                let checkBySalesPrice = false;
                if (productInCart.discount < 0){
                    realDiscount = productInCart.discount *-1;
                } else {
                    realDiscount = 0;
                    checkBySalesPrice = true;
                }
                let discount = realDiscount / 100;
                let discountValue                           = productInCart.priceList * discount;
                let discountValueDolar                      = discountValue / scope.base.dolar;
                
                let interest                                = scope.cart.header.paymentCondition.value / 100;
                let interestValue                           = ((checkBySalesPrice ? productInCart.salesPrice : productInCart.priceList) - discountValue) * interest;
                let interestValueDolar                      = interestValue / scope.base.dolar;
                let freightValue                            = subTotal * scope.base.priceAppData.freightData.shipping / 100;
                let freightValueDolar                       = freightValue;

                if (scope.cart.header.currency.value == 'USD') {
                    freightValue        = freightValueDolar * scope.base.dolar;
                }else {
                    freightValueDolar   = freightValue / scope.base.dolar;
                }
                
                let totalValue                              = item.quantity * productInCart.salesPrice;
                let totalValueWithInterest                  = item.quantity * productInCart.salesPriceWithInterest;
                let totalValueDolar                         = item.quantity * productInCart.salesPriceDolar;
                let totalValueWithInterestDolar             = item.quantity * productInCart.salesPriceWithInterestDolar;
                let quantityLiter                           = item.quantity * productInCart.liter;
                let pricePerLiter                           = totalValueWithInterest / quantityLiter;
                let pricePerLiterDolar                      = totalValueWithInterestDolar / quantityLiter;

                products.push({
                    id:                                 productInCart.id,
                    internalDeadlineDays:               scope.base.internalDeadlineDays,
                    itineraryDays:                      scope.base.itineraryDays,
                    discount:                           productInCart.discount,
                    maxDiscount:                        productInCart.maxDiscount,
                    minimumDiscount:                    productInCart.minimumDiscount,
                    pbEntry:                            productInCart.pbEntry,
                    recommendedDiscount:                productInCart.recommendedDiscount,
                    priceList:                          productInCart.priceList,
                    priceListDolar:                     productInCart.priceListDolar,
                    salesPrice:                         productInCart.salesPrice,
                    salesPriceDolar:                    productInCart.salesPriceDolar,
                    salesPriceWithInterest:             productInCart.salesPriceWithInterest,
                    salesPriceWithInterestDolar:        productInCart.salesPriceWithInterestDolar,
                    customerTypeDiscountValue:          customerTypeDiscountValue,
                    customerTypeDiscountValueDolar:     customerTypeDiscountValueDolar,
                    freightValue:                       freightValue,
                    freightValueDolar:                  freightValueDolar,
                    interest:                           (scope.cart.header.paymentCondition == null ? 0    : scope.cart.header.paymentCondition.valueInfo),
                    interestValue:                      interestValue,
                    interestValueDolar:                 interestValueDolar,
                    discountValue:                      discountValue,
                    discountValueDolar:                 discountValueDolar,
                    pricePerLiter:                      pricePerLiter,
                    pricePerLiterDolar:                 pricePerLiterDolar,
                    totalValue:                         totalValue,
                    totalValueWithInterest:             totalValueWithInterest,
                    totalValueDolar:                    totalValueDolar,
                    totalValueWithInterestDolar:        totalValueWithInterestDolar,
                    liter:                              quantityLiter,
                    discount:                           productInCart.discount,
                    shippingTableId:                    productInCart.shippingTableId,
                    discountPolicyId:                   productInCart.discountPolicyId,
                    customerTypeDiscountId:             productInCart.customerTypeDiscountId,
                    priceFromTable:                     productInCart.priceFromTable,
                    initialDate:                        productInCart.initialDate,
                    finishDate:                         productInCart.finishDate,
                    priceEntryId:                       productInCart.priceEntryId,
                    culture:                            productInCart.culture               == null ? null : productInCart.culture.id,
                    opportunityId:                      item.opportunityId,
                    itemId:                             item.itemId,
                    confirmed:                          item.confirmed,
                    confirmationDate:                   item.confirmationDate,
                    deliveryDate:                       item.date,
                    orderNumber:                        item.orderNumber,
                    quantity:                           item.quantity,
                    receiver:                           item.receiverAccount                == null ? null : item.receiverAccount.id,
                    ipiPercentage:                      productInCart.ipiPercentage,
                    dollarRate:                         scope.base.dolar
                });
            });

            scope.cart.products.forEach(function (item, index) {
                if (item.culture != null) {
                    let currCulture = allCultres.find(c => item.culture.id == c.id);
                    if (!currCulture) {
                        allCultres.push({
                            id: item.culture.id,
                            liter: item.quantityLiter
                        });
                    } else {
                        currCulture.liter += item.quantityLiter;
                    }
                }
            });
            let culture = null;
            if (allCultres.length > 0) {
                var max = allCultres[0].liter;
                var maxIndex = 0;    
                for (var i = 1; i < allCultres.length; i++) {
                    if (allCultres[i].liter > max) {
                        maxIndex = i;
                        max = allCultres[i].liter;
                    }
                }
                if (maxIndex != null) {
                    culture = allCultres[maxIndex];
                }                
            }

            var territoryData = Object.assign({}, scope.base.territoryData);
            if (scope.cart.header.selectedTerritory != null){
                territoryData = Object.assign({}, scope.cart.header.selectedTerritory);
            }

            delete territoryData['$$hashKey'];

            var opportunity = {
                id:                       scope.cart.header.oppId,
                priceReferenceDate:       scope.base.priceReferenceDate,
                priceAppData:             scope.base.priceAppData,
                selectedCurrency:         (scope.cart.header.currency            == null                         ? null  : scope.cart.header.currency.value),
                shipmentcondition:        (scope.cart.header.expedition          == null                         ? null  : scope.cart.header.expedition.value),
                orderType:                (scope.cart.header.orderType           == null                         ? null  : scope.cart.header.orderType.value),
                salesClassification:      (scope.cart.header.salesClassification == null                         ? null  : scope.cart.header.salesClassification.value),
                orderReason:              (scope.cart.header.orderReason         == null                         ? null  : scope.cart.header.orderReason.value),
                selectedAccountName:      (scope.cart.header.selectedAccount     == null                         ? ''    : scope.cart.header.selectedAccount.name),
                selectedAccount:          (scope.cart.header.selectedAccount     == null                         ? null  : scope.cart.header.selectedAccount.id),
                receiverAccount:          (scope.cart.header.receiverAccount     == null                         ? null  : scope.cart.header.receiverAccount.id),
                shipperAccount:           (scope.cart.header.shipperAccount      == null                         ? null  : scope.cart.header.shipperAccount.id),
                paymentCondition:         (scope.cart.header.paymentCondition    == null                         ? null  : scope.cart.header.paymentCondition.id),
                vendorDueDate:            (scope.cart.header.vendorDate          ?  scope.cart.header.vendorDate : null),
                interest:                 (scope.cart.header.paymentCondition    == null                         ? 0     : scope.cart.header.paymentCondition.value),
                totalAmountInterest:      scope.cart.totalInterest,
                totalAmountDolarInterest: scope.cart.totalDolarInterest,
                totalAmountDolar:         scope.cart.totalDolar,
                selectedCampaign:         (scope.cart.header.selectedCampaign    == null                         ? null :  scope.cart.header.selectedCampaign.id),
                isAgencied:               (scope.cart.header.isAgencied          == null                         ? false : scope.cart.header.isAgencied),
                orderNumber:              scope.cart.header.orderNumber,
                obsInternal:              scope.cart.header.obsInternal,
                obsLogistic:              scope.cart.header.obsLogistic,
                obsPrint:                 scope.cart.header.obsPrint,
                businessPlace:            scope.cart.header.businessPlace, 
                obsPrintNF:               scope.cart.header.obsPrintNF,
                territoryData:            territoryData,
                culture:                  (culture                               == null                         ? null  : culture.id),
                products:                 products,
                selectedBusinessPlace:    (scope.cart.header.selectedBusinessPlace == null ? null : scope.cart.header.selectedBusinessPlace.id),
                interestStartDate:        scope.cart.header.hasOwnProperty('interestStartDate')                  ? scope.cart.header.interestStartDate        : null,
                previousSelectedCampaign: scope.cart.header.hasOwnProperty('previousSelectedCampaign')           ? scope.cart.header.previousSelectedCampaign : null,
            };
            console.log(opportunity);
            callRemoteAction('OpportunityAppController.upsertOpportunity', opportunity, function (result, event) {
                scope.isLoading = false;
                if (event.status) {
                    if (!result.hasErrors) {
                        Swal.fire({
                            title: 'Show',
                            text: result.message,
                            type: 'success',
                            showCancelButton: false,
                            confirmButtonColor: '#3085d6',
                            confirmButtonText: 'OK'
                        }).then((result) => {
                            location.href = "#/header";
                            if (scope.pageView == 'edit') {
                                if (scope.oppId > ' ') {
                                    sforce.one.navigateToSObject(scope.oppId);
                                }
                            }else {
                                location.reload();
                            }
                        });
                    } else {
                        scope.isLoading = false;
                        scope.disableButton = false;
                        Log.fire(result, {code: '5544'});
                    }
                } else {
                    scope.isLoading = false;
                    Log.fire(event, {code: '5654'});
                }
                scope.$apply();
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

        var datesPerProducts = Object.keys(scope.cart.ship.dates);

        for (const key in scope.cart.products) {
            const product = scope.cart.products[key];
            product.shipDates = datesPerProducts.filter(function (value) {
                return scope.cart.ship.dates[value].hasOwnProperty(key);
            });
        }

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

        scope.formatPrice = function (price) {
            return formatMonetary(price, 2);
        };

        scope.calcTotalCartValue = function () {
            scope.cart.total = scope.cart.products.reduce(function (sum, num) {
                return sum + num.totalValue;
            }, 0);
            scope.cart.totalInterest = scope.cart.products.reduce(function (sum, num) {
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

})();

function roundTo(n, digits) {
    if (digits === undefined) {
        digits = 0;
    }
    var result = Number(
        (n).toLocaleString('pt-BR', {
            style: 'currency',
            currency: 'BRL',
            maximumFracionDigits: digits,
            minimumFractionDigits: digits,
        }).split(' ')[1].replace(/\./g, '').replace(',', '.')
    )
    
    return result;
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
        date = new Date(date+'T12:00');
    }
    if (typeof date == 'number') {
        date = new Date(date);
        return sSize(date.getUTCDate()) + '/' + sSize(date.getUTCMonth() + 1) + '/' + date.getUTCFullYear();
    }
    return sSize(date.getDate()) + '/' + sSize(date.getMonth() + 1) + '/' + date.getFullYear();
}

function formatDateForm(date) {
    if (typeof date == 'string') {
        date = new Date(date+'T12:00');
    }
    if (typeof date == 'number') {
        date = new Date(date);
        return sSize(date.getUTCFullYear()) + '-' + sSize(date.getUTCMonth() + 1) + '-' + sSize(date.getUTCDate());
    }
    return sSize(date.getFullYear()) + '-' + sSize(date.getMonth() + 1) + '-' + sSize(date.getDate());
}

function areDatesEqual(VAR_d1, VAR_d2) {
    if (typeof VAR_d1 == 'string') {
        VAR_d1 = new Date(VAR_d1+'T12:00');
    }
    if (typeof VAR_d1 == 'number') {
        VAR_d1 = new Date(VAR_d1);
    }
    if (typeof VAR_d2 == 'string') {
        VAR_d2 = new Date(VAR_d2+'T12:00');
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
        d1 = new Date(d1+'T12:00');
    }
    if (typeof d1 == 'number') {
        d1 = new Date(d1);
    }
    if (typeof d2 == 'string') {
        d2 = new Date(d2+'T12:00');
    }
    if (typeof d2 == 'number') {
        d2 = new Date(d2);
    }

    if (!(d1 instanceof Date) || !(d2 instanceof Date)){
        return false;
    }
    
    return d1.getTime() > d2.getTime() || areDatesEqual(d1, d2);
}

function isDateInRange(dt, d1, d2) {
    if (typeof dt == 'string') {
        dt = new Date(dt+'T12:00');
    }
    if (typeof dt == 'number') {
        dt = new Date(dt);
    }
    if (typeof d1 == 'string') {
        d1 = new Date(d1+'T12:00');
    }
    if (typeof d1 == 'number') {
        d1 = new Date(d1);
    }
    if (typeof d2 == 'string') {
        d2 = new Date(d2+'T12:00');
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
        VAR_d1 = new Date(VAR_d1+'T12:00');
    }
    if (typeof VAR_d1 == 'number') {
        VAR_d1 = new Date(VAR_d1);
    }
    if (typeof VAR_d2 == 'string') {
        VAR_d2 = new Date(VAR_d2+'T12:00');
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

function normalizeApexDate(dt) {
    dt.addDays(1);
    return dt;
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
        this.name             = options.name ? options.name.toString() : (++Calendar.counter).toString();
        this.endDate          = (datesArray.length > 0 ? new Date(Math.max.apply(null, datesArray)) : null);
        this.initDate         = (datesArray.length > 0 ? new Date(Math.min.apply(null, datesArray)) : options.initDate);
        this.avaliable        = options.dates;
        this.weekendAvaliable = options.weekendAvaliable;
        this.unavailableDates = options.unavailableDates;
        this.isOpen           = options.isOpen;
        this.greaterThanInit  = options.greaterThanInit;
        this.lessThanInit     = options.lessThanInit;
        this.contextDate      = new Date(this.initDate);
        this.callback         = callback;
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
                '       <div class="day-element wrapper ' + (this.selected.indexOf(dateFormated) > -1 ? 'active ' : '') + (areDatesEqual(this.dates[i], new Date()) ? 'today' : '') + (!this.isOpen ? (Object.keys(this.avaliable).length > 0 ? (typeof this.avaliable[dateFormated] == 'undefined' ? ' disabled' : '') : ' disabled') : (this.greaterThanInit ? (isEqualOrGreaterThan(dateFormated, this.initDate) ? '' : ' disabled') : '') + ' ' + (this.lessThanInit ? (isEqualOrGreaterThan(this.initDate, dateFormated)? '' : ' disabled') : '')) + (this.getWeekend(this.dates[i]) ? '' : ' disabled') + (this.isUnavailableDate(this.dates[i]) ? ' disabled' : ' ') + '">' +
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

        this.domElement.querySelectorAll('.day-element').forEach(function(element, index) {
            element.onclick = function(){
                self.selectDateCalendar(index, element);
            }
        });
        
        this.domElement.querySelectorAll('.next-month-arrow').forEach(function(element, index) {
            element.onclick = function(){
                self.nextMonth(true);
            }
        });

        this.domElement.querySelectorAll('.previous-month-arrow').forEach(function(element, index) {
            element.onclick = function(){
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

Calendar.create = function(id, options, callback){
    return new Calendar().initCalendar(id, options, callback);
}; 

function isUnavailableDate(dt, unavailableDates) {
    if (typeof unavailableDates == 'undefined') {
        unavailableDates = calendar.unavailableDates;
    }
    if (unavailableDates.indexOf(formatDateForm(dt)) > -1) {
        return true;
    }
    return false;
}

function isWeekend(dt) {
    let weekendDays = [0, 6];
    if (weekendDays.indexOf(dt.getDay()) > -1) {
        return true;
    }
    return false;
}

function getBusinessDate(currDate, days, unavailableDates, add) {
    let targetDate = new Date(currDate);
    do {
        targetDate.setDate(targetDate.getDate() + (1 * (add ? 1 : -1)));
        if (isWeekend(targetDate)) {
            continue;
        }
        if (isUnavailableDate(targetDate, unavailableDates)) {
            continue;
        }
        days--;
    } while (days > 0);
    return targetDate;
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

const Toast = Swal.mixin({
    toast: true,
    position: 'top-end',
    showConfirmButton: false,
    timer: 3000
});

const defaultErrorMessage = 'Algo deu errado, tente novamente. Se o problema persistir, contate um Administrador do Sistema.';

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
            html +=  ''+
                '<div class="collapsible left">'+
                '   <input type="checkbox" id="log-code-'+time+'" '+(opt.open ? 'checked="true"' : '')+' />' +
                '   <div class="collapsible-header">'+
                '       <label for="log-code-'+time+'">'+
                '           <svg class="slds-button__icon collapsible-down" aria-hidden="true">'+
                '               <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevrondown"></use>'+
                '           </svg>'+
                '           <svg class="slds-button__icon collapsible-up" aria-hidden="true">'+
                '               <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevronup"></use>'+
                '           </svg>'+
                '           <small>' + (opt.code != null ? 'CODE: [' + opt.code + ']' : 'Detalhes') + '</small>' +
                '       </label>'+
                '   </div>'+
                '   <div class="collapsible-body">' + ex.stackStrace + '</div>'+
                '</div>'
            ;
        } else if (opt.code != null) {
            html +=  ''+
                '<div class="collapsible">'+
                '   <div class="collapsible-header">'+
                '       <label for="log-code-'+time+'">'+
                '           <small>CODE: [' + opt.code + ']</small>' +
                '       </label>'+
                '   </div>'+
                '</div>'
            ;
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