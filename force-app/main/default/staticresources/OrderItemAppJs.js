
(function () {
    var orderItemApp = angular.module('orderItemApp', ['ngRoute', 'sf-lookup', 'floating-button']);

    orderItemApp.config(function ($routeProvider) {
        $routeProvider.
            when('/list', {
                templateUrl: window.URLS.orderItemList,
                controller: 'ListCtrl'
            }).
            otherwise({
                redirectTo: '/list'
            });
    });

    orderItemApp.controller('OrderItemCtrl', ['$scope', '$http', '$sce', '$filter', function (scope, http, $sce, $filter) {
        scope.hasMasterAccess = isCustomerService;
        scope.orderId = orderId;
        scope.orderNumber = orderNumber;
        scope.base = {
            arrOrderItem: []
        };
    }]);

    orderItemApp.controller('ListCtrl', ['$scope', '$http', function (scope, http) {
        scope.isLoading = true;

        scope.callRemote = function () {
            console.log('asdsd');
            scope.isLoading = true;
            var result = {
                hasErrors: false,
                data: [
                    {
                        "currencySymbol": "BRL",
                        "id": "9376hdaosid",
                        "unitPrice": 198.58,
                        "totalValue": 1985.85,
                        "billingDate": "2020-01-03",
                        "cancellingReason": "Errou",
                        "nrItem": "10",
                        "productId": "23456765esdf4",
                        "name": "Produto A",
                        "packing": "EB",
                        "sku": "XPTO",
                        "quantity": 120,
                        "scheduleDate": "2020-01-12",
                        "statusSAP": "Produto Indisponível",
                        "confirmedQuantity": 120,
                        "schedules": [{
                            "id": "rfghgrer44t",
                            "nrSchedule": "10",
                            "quantity": 60,
                            "confirmedQuantity": 0,
                            "scheduleDate": "2020-01-12",
                            "billingDate": "2020-01-12",
                            "statusSAP": "Produto Indisponível"
                        },
                        {
                            "id": "2334fmff",
                            "nrSchedule": "20",
                            "quantity": 60,
                            "confirmedQuantity": 60,
                            "scheduleDate": "2020-01-15",
                            "billingDate": "2020-01-15",
                            "statusSAP": "Produto Confirmado"
                        }
                        ]
                    },
                    {
                        "currencySymbol": "BRL",
                        "id": "aqewqeqwd2133",
                        "unitPrice": 198.58,
                        "totalValue": 1985.85,
                        "billingDate": "2020-01-03",
                        "cancellingReason": "Errou",
                        "nrItem": "20",
                        "productId": "23456765eskf4",
                        "name": "Produto B",
                        "packing": "EB",
                        "sku": "XPTZ",
                        "quantity": 120,
                        "scheduleDate": "2020-01-12",
                        "statusSAP": "Produto Indisponível",
                        "confirmedQuantity": 120,
                        "schedules": [{
                            "id": "rfghgrer44g",
                            "nrSchedule": "10",
                            "quantity": 60,
                            "confirmedQuantity": 0,
                            "scheduleDate": "2020-02-15",
                            "billingDate": "2020-02-15",
                            "statusSAP": "Produto Indisponível"
                        },
                        {
                            "id": "2334fmjf",
                            "nrSchedule": "20",
                            "quantity": 60,
                            "confirmedQuantity": 0,
                            "scheduleDate": "2020-05-18",
                            "billingDate": "2020-05-18",
                            "statusSAP": "Produto Indisponível"
                        }
                        ]
                    }
                ]
            };
            var event = {
                status: true
            };
            callRemoteAction('OrderItemAppController.getOrderItemListData', scope.orderId, function (result, event) {
                if (event.status) {
                    if (!result.hasErrors) {
                        scope.base.arrOrderItem = result.data;
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

        scope.formatScopeDate = function (dt) {
            return formatDate(dt);
        };

        scope.formatPrice = function (price) {
            return formatMonetary(price, 2);
        };

    }]);

    orderItemApp.controller('SectionCtrl', ['$scope', function (scope) {

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
            html += '' +
                '<div class="collapsible left">' +
                '   <input type="checkbox" id="log" />' +
                '   <div class="collapsible-header">' +
                '       <label for="log">' +
                '           <svg class="slds-button__icon collapsible-down" aria-hidden="true">' +
                '               <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevrondown"></use>' +
                '           </svg>' +
                '           <svg class="slds-button__icon collapsible-up" aria-hidden="true">' +
                '               <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#chevronup"></use>' +
                '           </svg>' +
                '           <small>' + (code != null ? 'CODE: [' + code + ']' : 'Ver log') + '</small>' +
                '       </label>' +
                '   </div>' +
                '   <div class="collapsible-body">' + ex.stackStrace + '</div>' +
                '</div>'
                ;
        } else if (code != null) {
            html += '' +
                '<div class="collapsible">' +
                '   <div class="collapsible-header">' +
                '       <label for="log">' +
                '           <small>CODE: [' + code + ']</small>' +
                '       </label>' +
                '   </div>' +
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