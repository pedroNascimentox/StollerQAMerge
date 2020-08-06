(function () {
    var shoppingCartApp = angular.module('shoppingCartApp', ['ngRoute']);

    shoppingCartApp.controller('ShoppingCtrl', ['$scope', '$http', '$sce', function (scope, http, $sce) {

        scope.containerClass = '';
        scope.summaryVision = false;
        scope.step = {
            title:              '',
            indicator:          '',
            quantityStep:       5,
            coords:             {
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
                }else {
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
            nextTitle:          '',
            actionNextStepText: '',
            actionNextStep:     null,
            actionBackStep:     null
        };
        scope.cart = {
            summaryVision: false,
            total: 0,
            culture: 'Soja',
            header: {},
            ship: {
                defaultDate: '2019-10-03',
                currentDate: '',
                dates: {},
            },
            products: []
        };
        scope.base = {
            dollar: 4.16,
            allProducts: [{
                    id: '6327267',
                    name: 'MOVER GL',
                    sku: 'PRD7610833',
                    priceList: 154.51,
                    liter: 30,
                    interest: 3,
                    inCart: false,
                    quantity: 0,
                    quantityLiter: 0,
                    totalValue: 0,
                    pricePerLiter: 0,
                    salesPrice: 154.51,
                    discount: 0,
                    shipDates: {},
                    detail: {
                        show: false
                    },
                    recent: false
                },
                {
                    id: '7756805',
                    name: 'HOLD',
                    sku: 'PRD5759117',
                    priceList: 167.71,
                    liter: 42,
                    interest: 10,
                    inCart: false,
                    quantity: 0,
                    quantityLiter: 0,
                    totalValue: 0,
                    pricePerLiter: 0,
                    salesPrice: 167.71,
                    discount: 0,
                    shipDates: {},
                    detail: {
                        show: false
                    },
                    recent: false
                },
                {
                    id: '6483726',
                    name: 'SETT',
                    sku: 'PRD1299867',
                    priceList: 219.38,
                    liter: 31,
                    interest: 1,
                    inCart: false,
                    quantity: 0,
                    quantityLiter: 0,
                    totalValue: 0,
                    pricePerLiter: 0,
                    salesPrice: 219.38,
                    discount: 0,
                    shipDates: {},
                    detail: {
                        show: false
                    },
                    recent: false
                },
                {
                    id: '2598495',
                    name: 'NITROPLUS',
                    sku: 'PRD4891838',
                    priceList: 128.83,
                    liter: 51,
                    interest: 7,
                    inCart: false,
                    quantity: 0,
                    quantityLiter: 0,
                    totalValue: 0,
                    pricePerLiter: 0,
                    salesPrice: 128.83,
                    discount: 0,
                    shipDates: {},
                    detail: {
                        show: false
                    },
                    recent: false
                },
                {
                    id: '2365571',
                    name: 'MASTERFIX',
                    sku: 'PRD1400240',
                    priceList: 212.09,
                    liter: 40,
                    interest: 4,
                    inCart: false,
                    quantity: 0,
                    quantityLiter: 0,
                    totalValue: 0,
                    pricePerLiter: 0,
                    salesPrice: 212.09,
                    discount: 0,
                    shipDates: {},
                    detail: {
                        show: false
                    },
                    recent: false
                },
                {
                    id: '2139475',
                    name: 'CO-MO',
                    sku: 'PRD6637788',
                    priceList: 172.65,
                    liter: 25,
                    interest: 8,
                    inCart: false,
                    quantity: 0,
                    quantityLiter: 0,
                    totalValue: 0,
                    pricePerLiter: 0,
                    salesPrice: 172.65,
                    discount: 0,
                    shipDates: {},
                    detail: {
                        show: false
                    },
                    recent: false
                },
                {
                    id: '5661603',
                    name: 'STIMULATE BD',
                    sku: 'PRD9680011',
                    priceList: 145.04,
                    liter: 10,
                    interest: 5,
                    inCart: false,
                    quantity: 0,
                    quantityLiter: 0,
                    totalValue: 0,
                    pricePerLiter: 0,
                    salesPrice: 145.04,
                    discount: 0,
                    shipDates: {},
                    detail: {
                        show: false,
                        lastSalesDate: '2017-05-22',
                        lastSalesQuantity: 22,
                        lastSalesPrice: 138.85,
                        lastSalesDiscount: 3,
                        lastSalesPricePerLitre: 4.80,
                        lastSalesPaymentCondition: '15'
                    },
                    recent: true
                }, {
                    id: '1823035',
                    name: 'RIZOTEC S2',
                    sku: 'PRD8050925',
                    priceList: 233.35,
                    liter: 15,
                    interest: 2,
                    inCart: false,
                    quantity: 0,
                    quantityLiter: 0,
                    totalValue: 0,
                    pricePerLiter: 0,
                    salesPrice: 233.35,
                    discount: 0,
                    shipDates: {},
                    detail: {
                        show: false,
                        lastSalesDate: '2017-03-21',
                        lastSalesQuantity: 50,
                        lastSalesPrice: 204.50,
                        lastSalesDiscount: 14,
                        lastSalesPricePerLitre: 7.73,
                        lastSalesPaymentCondition: '30'
                    },
                    recent: true
                }, {
                    id: '2840914',
                    name: 'PHYTOGARD BB',
                    sku: 'PRD2040414',
                    priceList: 210.97,
                    liter: 20,
                    interest: 9,
                    inCart: false,
                    quantity: 0,
                    quantityLiter: 0,
                    totalValue: 0,
                    pricePerLiter: 0,
                    salesPrice: 210.97,
                    discount: 0,
                    shipDates: {},
                    detail: {
                        show: false,
                        lastSalesDate: '2017-04-9',
                        lastSalesQuantity: 40,
                        lastSalesPrice: 181.84,
                        lastSalesDiscount: 1,
                        lastSalesPricePerLitre: 8.70,
                        lastSalesPaymentCondition: '60'
                    },
                    recent: true
                }
            ],
            freightTypes: [{
                    label: 'CIF',
                    value: 'CIF',
                    isDefault: true
                },
                {
                    label: 'FOB',
                    value: 'FOB'
                }
            ],
            currencies: [{
                    label: 'BRL',
                    value: 'BRL',
                    isDefault: true
                },
                {
                    label: 'USD',
                    value: 'USD'
                }
            ],
            paymentConditions: [{
                    label: '30D',
                    value: '30D',
                    isDefault: true
                },
                {
                    label: '45D',
                    value: '45D'
                },
                {
                    label: 'A VISTA',
                    value: 'A VISTA'
                },
            ],
            expeditions: [{
                    label: 'Fracionado',
                    value: 'Fracionado',
                    isDefault: true,
                },
                {
                    label: 'Cotação',
                    value: 'Cotação'
                }
            ],
            orderTypes: [{
                    label: 'Normal',
                    value: 'Normal',
                    isDefault: true,
                },
                {
                    label: 'Conta e Ordem',
                    value: 'Conta e Ordem',
                },
                {
                    label: 'Remanejamento',
                    value: 'Remanejamento',
                },
                {
                    label: 'Bonificação',
                    value: 'Bonificação',
                }
            ],
            salesClassifications: [{
                    label: 'Normal',
                    value: 'Normal',
                    isDefault: true
                },
                {
                    label: 'Campanha',
                    value: 'Campanha',
                    isCampaignClassification: true
                },
                {
                    label: 'Barter Campanha',
                    value: 'Barter Campanha',
                    isCampaignClassification: true
                },
                {
                    label: 'Barter',
                    value: 'Barter',
                    isCampaignClassification: true
                }
            ],
            cultures: [{
                    label: 'Soja',
                    value: 'Soja',
                    isDefault: true,
                },
                {
                    label: 'Milho',
                    value: 'Milho',
                },
                {
                    label: 'Algodão',
                    value: 'Algodão',
                },
                {
                    label: 'Cana',
                    value: 'Cana',
                }
            ]
        };
        scope.cart.header = {
            freightType: scope.base.freightTypes.find(a => a.isDefault),
            currency: scope.base.currencies.find(a => a.isDefault),
            paymentCondition: scope.base.paymentConditions.find(a => a.isDefault),
            expedition: scope.base.expeditions.find(a => a.isDefault),
            orderType: scope.base.orderTypes.find(a => a.isDefault),
            salesClassification: scope.base.salesClassifications.find(a => a.isDefault)
        };

        scope.trustAsHtml = function (html) {
            return $sce.trustAsHtml(html);
        }

    }]);

    shoppingCartApp.config(function ($routeProvider) {
        $routeProvider.
            when('/header', {
                templateUrl: window.URLS.shoppingCartPrototypeAppHeader,
                controller: 'HeaderCtrl'
            }).
            when('/productlist', {
                templateUrl: window.URLS.shoppingCartPrototypeAppProductList,
                controller: 'ProductCtrl'
            }).
            when('/cart', {
                templateUrl: window.URLS.shoppingCartPrototypeAppCart,
                controller: 'CartCtrl'
            }).
            when('/ship', {
                templateUrl: window.URLS.shoppingCartPrototypeAppShip,
                controller: 'ShipCtrl'
            }).
            when('/summary', {
                templateUrl: window.URLS.ShoppingCartPrototypeAppSummary,
                controller: 'SummaryCtrl'
            }).
            otherwise({
                redirectTo: '/header'
            });
    });

    shoppingCartApp.controller('HeaderCtrl', ['$scope', '$http', function (scope, $http) {
        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.$parent.step.title = 'Nova Oportunidade';
        scope.$parent.step.actionNextStepText = 'Avançar';
        scope.$parent.step.indicator = 1;
        scope.$parent.step.nextTitle = 'Próximo: Catálogo';
        scope.$parent.step.calcCoords();
        scope.$parent.step.actionNextStep = function () {
            location.href = "#/productlist";
        };
        scope.$parent.step.actionBackStep = function () {
            location.href = "#/header";
        };
    }]);
    
    shoppingCartApp.controller('SectionCtrl', ['$scope',  function (scope) {

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

    shoppingCartApp.controller('ProductCtrl', ['$scope', '$http', function (scope, http) {
        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.$parent.step.title = 'Catálogo';
        scope.$parent.step.actionNextStepText = 'Avançar';
        scope.$parent.step.indicator = 2;
        scope.$parent.step.nextTitle = 'Próximo: Quantidade e Preço';
        scope.$parent.step.actionNextStep = function () {
            scope.$parent.cart.products = scope.base.allProducts.filter(function (p) {
                return p.inCart;
            });
            if (scope.$parent.cart.products.length > 0) {
                location.href = "#/cart";                
            }

        };
        scope.$parent.step.actionBackStep = function () {
            location.href = "#/header";
        };
        scope.$parent.step.calcCoords();
        scope.termSearch;

        if (!scope.allProducts) {
            scope.allProducts = scope.$parent.base.allProducts;
        }

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

    }]);
    
    shoppingCartApp.controller('CartCtrl', ['$scope', '$http', function (scope, http) {
        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.$parent.step.title = 'Quantidade e Preço';
        scope.$parent.step.actionNextStepText = 'Avançar';
        scope.$parent.step.indicator = 3;
        scope.$parent.step.nextTitle = 'Próximo: Datas de Entrega';
        scope.$parent.step.calcCoords();
        scope.$parent.step.actionNextStep = function () {
            var allQuantity = scope.products.reduce(function (sum, num) {
                return sum + num.quantity
            }, 0);
            if (allQuantity > 0) {
                location.href = "#/ship";                
            }
        };
        scope.$parent.step.actionBackStep = function () {
            location.href = "#/productlist";
        };
        scope.products = scope.$parent.cart.products;

        scope.totalItem = function (p) {
            p.totalValue = p.quantity * p.salesPrice;
            p.totalValue = p.totalValue - (p.totalValue * (p.discount / 100));
            return scope.formatPrice(p.totalValue);
        };
        
        scope.totalItemDolar = function (p) {
            return scope.formatPrice(p.totalValue / scope.$parent.base.dollar);
        };

        scope.formatPrice = function (price) {
            return formatMonetary(price, 2);
        };

        scope.increment = function (p) {
            p.quantity += 10;
            scope.discountChange(p);
            return p.quantity;
        };
        
        scope.decrement = function (p) {
            p.quantity -= 10;
            if (p.quantity < 0) {
                p.quantity = 0;
            }
            scope.discountChange(p);
            return p.quantity;
        };

        scope.quantityChange = function (p) {
            scope.discountChange(p);
        };
        
        scope.incrementDiscount = function (p) {
            p.discount += 5;
            if (p.discount > 100) {
                p.discount = 100;
            }
            scope.discountChange(p);
            return p.discount;
        };
        
        scope.decrementDiscount = function (p) {
            p.discount -= 5;
            if (p.discount < 0) {
                p.discount = 0;
            }
            scope.discountChange(p);
            return p;
        };

        scope.discountChange = function(p) {
            if (p.discount < 0 || p.discount == undefined) {
                p.discount = 0;
            }
            p.salesPrice = parseFloat((p.priceList - (p.priceList * (p.discount / 100))).toFixed(2));
        };
        
        scope.salesPriceChange = function(p) {
            if (p.salesPrice <= p.priceList && p.salesPrice > 0) {
                var diff = p.priceList - p.salesPrice;
                diff = (diff * 100) / p.priceList;
                p.discount = parseFloat(diff.toFixed(2));
            }else {
                p.salesPrice = p.priceList;
                p.discount = 0;
            }
        };

        scope.calcQuantityLiter = function (p) {
            p.quantityLiter = p.quantity * p.liter;
            return p.quantityLiter;
        };
        
        scope.calcPricePerLiter = function (p) {
            if (p.quantityLiter > 0) {
                p.pricePerLiter = p.totalValue / p.quantityLiter;
            }else {
                p.pricePerLiter = 0;
            }
            return scope.formatPrice(p.pricePerLiter);                
        };
        
        scope.calcTotalCartValue = function () {
            scope.$parent.cart.total = scope.products.reduce(function (sum, num) {
                return sum + num.totalValue
            }, 0);
            return scope.formatPrice(scope.$parent.cart.total);
        };
        
        scope.calcTotalCartValueDolar = function () {
            return scope.formatPrice(scope.$parent.cart.total / scope.$parent.base.dollar);
        };

        scope.getPtax = function () {
            return scope.formatPrice(scope.$parent.base.dollar);
        }

    }]);
    
    shoppingCartApp.controller('ShipCtrl', ['$scope', '$http', function (scope, http) {
        window.scrollTo(0, 0);
        scope.$parent.containerClass = '';
        scope.$parent.step.title = 'Datas de Entrega';
        scope.$parent.step.actionNextStepText = 'Avançar';
        scope.$parent.step.indicator = 4;
        scope.$parent.step.nextTitle = 'Próximo: Resumo e confirmação';
        scope.$parent.step.calcCoords();
        scope.$parent.step.actionNextStep = function () {
            location.href = "#/summary";
        };
        scope.$parent.step.actionBackStep = function () {
            location.href = "#/cart";
        };
        scope.products = scope.$parent.cart.products;
               
        scope.oldDate = '';
        scope.cart = scope.$parent.cart;
        scope.showCalendar  = false;
        scope.showMoreDates = true;

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

        var arrDates = Object.keys(scope.cart.ship.dates);
        scope.currentDate = scope.cart.ship.currentDate;
        if (!scope.currentDate) {
            if (arrDates.length > 0) {
                scope.currentDate = arrDates[0];
            } else {
                scope.currentDate = scope.cart.ship.defaultDate;
            }            
        }

        scope.productExistDate = function (p) {
            if (scope.cart.ship.dates.hasOwnProperty(scope.currentDate)) {
                return (scope.cart.ship.dates[scope.currentDate].hasOwnProperty(p.id));                
            }
            return false;
        }

        scope.validateShowMoreDate = function () {
            for (let i = 0; i < scope.products.length; i++) {
                const product = scope.products[i];
                var sumProduct = 0;
                for (const key in scope.cart.ship.dates) {
                    if (scope.cart.ship.dates.hasOwnProperty(key)) {
                        const elementDate = scope.cart.ship.dates[key];
                        if (elementDate.hasOwnProperty(product.id)) {
                            const element = elementDate[product.id];
                            sumProduct += element.quantity;
                            if (element.quantity <= 0 && product.balance <= 0) {
                                delete scope.cart.ship.dates[key][product.id];
                            }
                        }
                        if (Object.keys(scope.cart.ship.dates[key]).length <= 0) {
                            delete scope.cart.ship.dates[key];
                        }
                    }
                }
                var totalInShip = (product.balance + sumProduct);
                var diff = product.quantity - totalInShip;
                if (diff > 0) {
                    product.balance += diff;
                }else {
                    diff = totalInShip - Math.abs(diff);
                    for (const key in scope.cart.ship.dates) {
                        if (scope.cart.ship.dates.hasOwnProperty(key)) {
                            const elementDate = scope.cart.ship.dates[key];
                            if (elementDate.hasOwnProperty(product.id)) {
                                const element = elementDate[product.id];
                                if (element.quantity <= diff) {
                                    diff -= element.quantity;
                                }else if (diff > 0) {
                                    scope.cart.ship.dates[key][product.id].quantity = diff;
                                    diff = 0;
                                }else {
                                    delete scope.cart.ship.dates[key][product.id];
                                }
                            }
                            if (Object.keys(scope.cart.ship.dates[key]).length <= 0) {
                                delete scope.cart.ship.dates[key];
                            }
                        }
                    }
                }
            }
            var arrDates = Object.keys(scope.cart.ship.dates);
            if (arrDates.indexOf(scope.currentDate) < 0) {
                if (arrDates.length > 0) {
                    scope.currentDate = arrDates[0];
                } else {
                    scope.currentDate = scope.cart.ship.defaultDate;
                }
            }
            var allBalance = scope.products.reduce(function (sum, num) {
                if (num.hasOwnProperty('balance')) {
                    return sum + num.balance;
                }
                return sum + 0;
            }, 0);
            if (allBalance <= 0) {
                scope.showMoreDates = false;
                return false;
            }
            if (Object.keys(scope.cart.ship.dates).length > 4) {
                scope.showMoreDates = false;
            } else {
                scope.showMoreDates = true;
            }
                       
        };

        scope.prepareDate = function (dt, copy) {
            scope.$parent.cart.ship.currentDate = dt;
            if (!scope.cart.ship.dates[dt]) {
                scope.cart.ship.dates[dt] = {};
                if (copy) {
                    scope.cart.ship.dates[dt] = scope.cart.ship.dates[scope.oldDate];
                    delete scope.cart.ship.dates[scope.oldDate];
                }
            }else {
                if (copy) {
                    for (const key in scope.cart.ship.dates[scope.oldDate]) {
                        if (scope.cart.ship.dates[dt].hasOwnProperty(key)) {
                            const element = scope.cart.ship.dates[dt][key];
                            element.quantity += scope.cart.ship.dates[scope.oldDate][key].quantity;
                        }else {
                            scope.cart.ship.dates[dt][key] = {
                                name: scope.cart.ship.dates[scope.oldDate][key].name,
                                quantity: scope.cart.ship.dates[scope.oldDate][key].quantity,
                                confirmed: false
                            };
                        }
                    }
                    delete scope.cart.ship.dates[scope.oldDate];
                }
            }
            if (!copy) {
                var arrProducts = scope.products.filter(function (item) {
                    if (item.quantity > 0) {
                        if (!item.hasOwnProperty('balance')) {
                            item.balance = item.quantity;
                        }                        
                    }else {
                        return false;
                    }
                    return item.balance > 0;
                });
                for (let i = 0; i < arrProducts.length; i++) {
                    const element = arrProducts[i];
                    if (!scope.cart.ship.dates[dt].hasOwnProperty(element.id)) {
                        scope.cart.ship.dates[dt][element.id] = {
                            name: element.name,
                            quantity: element.balance,
                            confirmed: false
                        };
                        element.balance = 0;
                    }
                }
            }
            scope.showCalendar = false;
            scope.validateShowMoreDate();
        };

        scope.init = function (params) {
            for (let i = 0; i < scope.products.length; i++) {
                const element = scope.products[i];
                if (!element.hasOwnProperty('balance') && element.quantity > 0) {
                    element.balance = element.quantity;
                }
            }
            scope.prepareDate(scope.currentDate, false);
            initCalendar('wrapper-calendar', {
                        dates: [],
                        initDate: '2019-10-03',
                        isOpen: true,
                        greaterThanInit: true
                    }, function (result) {
                scope.setDate(result);
            });
        };

        scope.init();

        scope.setDate = function(dt) {
            scope.oldDate = scope.currentDate;
            scope.$parent.cart.ship.currentDate = scope.currentDate = dt;
            calendar.selected = [];
            scope.$apply();
        };

        scope.openCalendar = function() {
            if (scope.currentDate == '') {
                scope.showCalendar = !scope.showCalendar;
            } else {
                scope.showCalendar = true;
                scope.currentDate = '';
            }
            calendar.selected = [];
        };
        
        scope.openSelectedDate = function (dt) {
            if (scope.currentDate == dt) {
                scope.showCalendar = !scope.showCalendar;
            }else {
                scope.oldDate       = null;
                scope.currentDate   = dt;
                scope.showCalendar  = false;
            }
            calendar.selected = [dt];
            // scope.$apply();
        };

        scope.$watch("currentDate", function (newValue, oldValue) {
            if (newValue != oldValue && newValue > ' ') {
                scope.prepareDate(newValue, (oldValue > ' ' && scope.oldDate));
            }
        });

        scope.increment = function (p) {
            scope.quantityChange(p, true, true);
        };

        scope.decrement = function (p) {
            scope.quantityChange(p, true, false);
        };

        scope.quantityChange = function (p, helper, plus) {
            var newQuantityDate = scope.$parent.cart.ship.dates[scope.currentDate][p.id].quantity;
            if (helper) {
                if (plus) {
                    newQuantityDate += (p.balance > 10 ? 10 : p.balance);
                }else {
                    newQuantityDate -= 10;
                }
            }
            if (newQuantityDate < 0) {
                newQuantityDate = 0;
            }
            if (newQuantityDate > 0) {
                newQuantityDate = roundTo(newQuantityDate);
            }
            scope.$parent.cart.ship.dates[scope.currentDate][p.id].quantity = newQuantityDate;
            var allQuantityProduct = 0;
            var currDateQuantity = 0;
            for (const key in scope.$parent.cart.ship.dates) {
                if (scope.$parent.cart.ship.dates.hasOwnProperty(key)) {
                    if (scope.$parent.cart.ship.dates[key].hasOwnProperty(p.id)) {
                        const element = scope.$parent.cart.ship.dates[key][p.id];
                        allQuantityProduct += element.quantity;
                        if (key == scope.currentDate) {
                            currDateQuantity += element.quantity;
                        }
                    }
                }
            }
            var preBalance = p.quantity - allQuantityProduct
            if (preBalance < 0) {
                scope.$parent.cart.ship.dates[scope.currentDate][p.id].quantity = p.quantity - (allQuantityProduct - currDateQuantity);
                scope.quantityChange(p, false, false);
                return false;
            }
            p.balance = preBalance;
            scope.validateShowMoreDate();
        };

    }]);

    shoppingCartApp.controller('SummaryCtrl', ['$scope', '$http', function (scope, http) {
        window.scrollTo(0, 0);
        scope.$parent.step.title = 'Resumo e confirmação';
        scope.$parent.step.actionNextStepText = 'Confirmar';
        scope.$parent.step.indicator = 5;
        scope.$parent.step.nextTitle = '\u00A0';
        scope.$parent.step.calcCoords();
        scope.$parent.step.actionNextStep = function () {};
        scope.$parent.step.actionBackStep = function () {
            location.href = "#/ship";
        };
        scope.products = scope.$parent.cart.products;
        scope.$parent.containerClass = 'summary';

        scope.summaryVision = false;

        scope.cart = scope.$parent.cart;

        var datesPerProducts = Object.keys(scope.$parent.cart.ship.dates);

        for (let i = 0; i < scope.$parent.cart.products.length; i++) {
            const product = scope.$parent.cart.products[i];
            product.shipDates = datesPerProducts.filter(function (value) {
                return scope.$parent.cart.ship.dates[value].hasOwnProperty(product.id);
            });
        }

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

        scope.formatPrice = function (price) {
            return formatMonetary(price, 2);
        };

        scope.calcTotalCartValue = function () {
            scope.cart.total = scope.products.reduce(function (sum, num) {
                return sum + num.totalValue
            }, 0);
            return scope.formatPrice(scope.cart.total);
        };

        scope.calcTotalCartValueDolar = function () {
            return scope.formatPrice(scope.cart.total / scope.$parent.base.dollar);
        };

    }]);

    function roundTo(n, digits) {
        if (digits === undefined) {
            digits = 0;
        }

        var multiplicator = Math.pow(10, digits);
        n = parseFloat((n * multiplicator).toFixed(11));
        return Math.round(n) / multiplicator;
    }

    function formatMonetary(v, d) {
        if (typeof d == 'undefined') {
            d = 2;
        }
        v = roundTo(v, d);
        var VAR_parsed = v.toString().split('.'),
            VAR_buffer = '',
            VAR_decimal = '',
            VAR_total = VAR_parsed[0].length;
        if (VAR_total > 0)
            while (VAR_total != 0) {
                if (VAR_total % 3 == 0 && VAR_buffer > ' ') {
                    VAR_buffer += '.';
                }
                VAR_buffer += VAR_parsed[0].substring(0, 1);
                VAR_parsed[0] = VAR_parsed[0].substring(VAR_total, 1);
                VAR_total--;
            }
        if (VAR_parsed.length > 1 && d > 0) {
            var l = VAR_parsed[1].length;
            VAR_decimal = ',' + VAR_parsed[1].substring(0, (l > d ? d : l));
            d++;
            while (VAR_decimal.length < d) VAR_decimal += '0';
            VAR_buffer += VAR_decimal;
        } else {
            while (VAR_decimal.length < d) VAR_decimal += '0';
            if (d > 0 && VAR_decimal > ' ') {
                VAR_buffer += ',' + VAR_decimal;
            }
        }
        return VAR_buffer;
    }

})();


function sSize(VAR_text) {
    return (VAR_text < 10 ? '0' + VAR_text : VAR_text)
}

function formatDate(date) {
    if (typeof date == 'string' || typeof date == 'number') {
        date = new Date(date);
    }
    return sSize(date.getUTCDate()) + '/' + sSize(date.getUTCMonth() + 1) + '/' + date.getFullYear();
}

function formatDateForm(date) {
    if (typeof date == 'string' || typeof date == 'number') {
        date = new Date(date);
    }
    return sSize(date.getUTCFullYear()) + '-' + sSize(date.getUTCMonth() + 1) + '-' + sSize(date.getUTCDate());
}

function compareDates(VAR_d1, VAR_d2) {
    if (typeof VAR_d1 == 'string') {
        VAR_d1 = new Date(VAR_d1);
    }
    if (typeof VAR_d2 == 'string') {
        VAR_d2 = new Date(VAR_d2);
    }
    VAR_d1 = VAR_d1.getUTCFullYear() + '-' + VAR_d1.getUTCMonth() + '-' + VAR_d1.getUTCDate();
    VAR_d2 = VAR_d2.getUTCFullYear() + '-' + VAR_d2.getUTCMonth() + '-' + VAR_d2.getUTCDate();
    if (VAR_d1 == VAR_d2) {
        return true;
    }
    return false;
}

function compareMonths(VAR_d1, VAR_d2) {
    if (typeof VAR_d1 == 'string') {
        VAR_d1 = new Date(VAR_d1);
    }
    if (typeof VAR_d2 == 'string') {
        VAR_d2 = new Date(VAR_d2);
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
     calendar.isOpen = options.isOpen;
     calendar.greaterThanInit = options.greaterThanInit;
     calendar.contextDate = new Date(calendar.initDate);
     calendar.callback = callback;
     document.getElementById(id).innerHTML = '<table class="calendar"></table>';
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
             '       <div onclick="selectDateCalendar(' + i + ', this);" class="wrapper ' + (calendar.selected.indexOf(dateFormated) > -1 ? 'active ' : '') + (compareDates(calendar.dates[i], new Date()) ? 'today' : '') + (!calendar.isOpen ? (Object.keys(calendar.avaliable).length > 0 ? (typeof calendar.avaliable[dateFormated] == 'undefined' ? ' disabled' : '') : ' disabled') : (calendar.greaterThanInit ? (dateFormated >= calendar.initDate ? '' : ' disabled') : '')) + '">' +
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
        calendar.contextDate.setMonth(calendar.contextDate.getUTCMonth() + 1);
    } else {
        calendar.contextDate.setMonth(calendar.contextDate.getUTCMonth() - 1);
    }
    setDaysCalendar();
}

function Request() {

    var request;

    if (window.XMLHttpRequest) {
        request = new XMLHttpRequest();
    } else {
        request = new ActiveXObject("Microsoft.XMLHTTP");
    }

    this.send = function (data, callback) {

        var method = '',
            parameters = '';

        // if (typeof request == 'undefined') {
        //     if (window.XMLHttpRequest) request = new XMLHttpRequest();
        //     else request = new ActiveXObject("Microsoft.XMLHTTP");
        // }

        request.onreadystatechange = function () {
            callback(request.readyState, request.status, request.responseText);
        };

        switch (data.method) {
            case 'GET':
                method = 'GET';
                break;
            case 'POST':
                method = 'POST';
                break;
            default:
                method = 'GET';
        }

        if (typeof data.parameters != 'undefined') {

            if (typeof data.headers['Content-Type'] != 'undefined' &&
                (data.headers['Content-Type'] == 'application/json;charset=UTF-8' ||
                    data.headers['Content-Type'] == 'application/json')) {
                parameters = JSON.stringify(data.parameters);
            } else {
                parameters = data.parameters;
            }
        }

        request.open(method, data.url + (method == 'GET' ? parameters : ''), data.synchronous);

        if (typeof data.headers != 'undefined')
            for (var header in data.headers) {
                request.setRequestHeader(header, data.headers[header]);
            }

        request.send((method == 'POST' ? parameters : null));
    };

}
Request.instance = null;
Request.getInstance = function () {
    // if (this.instance == null) this.instance = new Request();
    this.instance = new Request();
    return this.instance;
};

Request.send = function (data, callback) {
    Request.getInstance().send(data, callback);
};

function remoteCallPost(url, data, toQueryString, callback) {
    remoteCall('POST', url, data, toQueryString, callback);
}

function remoteCallGet(url, data, toQueryString, callback) {
    remoteCall('GET', url, data, toQueryString, callback);
}

function remoteCall(method, url, data, toQueryString, callback) {
    var headers = {
        'Content-Type': 'application/json;charset=UTF-8'
    };
    Request.send({
        method: method,
        parameters: data,
        headers: {},
        url: url + (toQueryString ? jsonToQueryString(data) : ''),
        synchronous: true
    }, function (readyState, status, response) {
        if (readyState == 4) {
            try {
                response = JSON.parse(response);
            } catch (e) {
                response = {
                    message: {
                        type: 'warning',
                        title: 'Ops',
                        text: 'Algo deu errado, tente novamente em alguns instantes!'
                    }
                };
            } finally {
                setTimeout(function () {
                    callback(response);
                }, 1);
            }
        }
    });
}