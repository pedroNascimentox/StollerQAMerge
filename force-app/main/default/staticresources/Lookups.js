angular.module('sf-lookup', [])
.controller('LookupController', function($scope){
})
.directive('sfLookup', function($timeout){
    return {
        restrict: 'E',
        require: 'ngModel', 
        scope:{
            ngModel: '=',
            ngDisabled: '=',
            values: '=',
            filters: '=',
            searchTarget: '=',
            subtitle: '=',
            title: '=',
            required: '=',
            remoteMethod: '@',
            returnedFields: '='
        },
        templateUrl: window.URLS.lookupTemplate,
        link: function($scope, element, attrs, $model){

            $scope.isStatic = 'values' in attrs;
            $scope.queryResults = [];

            if ($scope.isStatic){
                $scope.queryResults = Object.assign([], $scope.values);
                $scope.searchMessage = 'Todos os resultados:'
            }

            $scope.label        = attrs['label'];
            $scope.iconPath     = attrs['iconPath'];
            $scope.placeholder  = attrs['placeholder'];
            $scope.isDisabled   = attrs['ngDisabled'];
            
            let remoteMethod = attrs['remoteMethod'] || window.URLS.SEARCH_LOOKUP;
            
            $scope.TYPING_INTERVAL = 1500;
            
            $scope.typingTimeout = void 0;
            
            $scope.defaultTitle = $scope.defaultSubtitle = function(record){
                if (typeof record == 'undefined') {
                   record = {};
                }
                if (typeof (record.name || record.Name) == 'undefined') {
                    record.name = '';
                }
                return (record.name || record.Name);
            };

            $scope.selectedRecord = void 0;
            $scope.getTitle = $scope.title || $scope.defaultSubtitle;
            $scope.getSubtitle = $scope.subtitle || $scope.defaultTitle;

            $scope.isRunning = true;
            $scope.isSearching = false;
            $scope.isTyping = false;
            $scope.isMouseDownEvent = false;
            $scope.showStaticResults = false;

            $scope.searchTerm = '';

            $scope.callUpdate = function(){
                if ($scope.typingTimeout){
                    $timeout.cancel($scope.typingTimeout);
                }

                let interval = $scope.isStatic? 0 : $scope.TYPING_INTERVAL;

                if ($scope.searchTerm){

                    if (!$scope.isStatic){
                        $scope.queryResults = [];
                        $scope.searchMessage = `Pesquisando por "${$scope.searchTerm}"...`
                    }
                    
                    $scope.typingTimeout = $timeout(function(){
                        if (!$scope.isStatic){
                            $scope.query();
                        } else {
                            $scope.filterByUserInput();
                        }
                    }, interval);

                    $scope.isSearching = true;
                    
                } else {
                    $scope.isSearching = false;    
                    
                    if ($scope.isStatic){
                        $scope.queryResults = Object.assign([], $scope.values);
                        $scope.searchMessage = $scope.queryResults.length? 'Todos os resultados:' : 'Nenhum resultado encontrado.'
                        $scope.showStaticResults = true;
                    }
                }
            };

            $scope.filterByUserInput = function(){
                let filterFields = ($scope.searchTarget || '').concat('name');

                if ($scope.values){
                    $scope.queryResults = $scope.values.filter(a => {
                        for (let filter of filterFields.split(';')){
                            if (a[filter] && a[filter].toString().toLowerCase().includes($scope.searchTerm.toLowerCase())) {
                                return true;
                            }
                        }
                    });
                }
                $scope.searchMessage = $scope.queryResults && $scope.queryResults.length ? `Exibindo resultados para: "${$scope.searchTerm}"` : `Nenhum resultado encontrado para "${$scope.searchTerm}".`
                $scope.isSearching = false;
            };

            $scope.query = function(){
                callLookupRemoteAction(remoteMethod, {
                    searchTerm: $scope.searchTerm,
                    tableName:  attrs['object'],
                    filters:    $scope.filters,
                    searchTarget: $scope.searchTarget,
                    returnedFields: $scope.returnedFields,
                    
                }, function(result, event){

                    console.log(event);

                    if (event.status) {
                        if (!result.hasErrors) {
                            $scope.isSearching      = false;
                            $scope.searchMessage    = result.length? `Exibindo resultados para: "${$scope.searchTerm}"` : `Nenhum resultado encontrado para "${$scope.searchTerm}".`
                            $scope.queryResults     = result;
                            $scope.$apply();
                        } else {
                            $scope.$apply();
                            Log.fire(result, {
                                code: '4489'
                            });
                        }
                    } else {
                        $scope.$apply();
                        Log.fire(event, {
                            code: '4498'
                        });
                    }

                })
            };

            $scope.preventBlur = function(){
                $scope.isMouseDownEvent = true;
            };

            $scope.selectRecord = function(record){
                $scope.selectedRecord = record;
                $scope.isSelected = true;

                $scope.isMouseDownEvent = false;

                $model.$setViewValue(record);
                $model.$render();
            };  

            $scope.startSearch = function(){
                $scope.isTyping = true;
            };
            
            $scope.stopSearch = function(){
                $scope.isTyping = false;
                $scope.queryResults = [];
                if ($scope.typingTimeout){
                    $timeout.cancel($scope.typingTimeout);
                }
                $scope.searchTerm = '';
            };

            $scope.reset = function(){
                $scope.searchTerm = '';
                $scope.isTyping = false;
                $scope.isSelected = false;
                $scope.queryResults = [];
                $scope.showStaticResults = false;

                $model.$setViewValue(null);
                $model.$render();
            };

            element.bind('focusout', function(e){
                if (!$scope.isMouseDownEvent){
                    $scope.isSearching = false;
                    $scope.reset();
                    $scope.$apply();
                }
            });
            
            element.bind('focusin', function(e){
                if ($scope.isStatic){
                    $scope.queryResults = $scope.values.filter(a => a.name.toLowerCase().includes($scope.searchTerm.toLowerCase()));
                    $scope.searchMessage = $scope.queryResults.length? 'Todos os resultados:' : 'Não foram encontrados resultados.';
                    $scope.showStaticResults = true;
                    $scope.$apply();
                }
            });

            var reseting;
            $scope.$watch('ngModel', function(model){
                if (model == null && !reseting){
                    reseting = true;
                    $scope.reset();
                    reseting = false;
                } else if (model != null && !reseting){
                    reseting = true;
                    $scope.isSelected = true;
                    $scope.selectedRecord = $scope.ngModel;
                    reseting = false;
                }
            }, true);
            
            $scope.$watch('ngDisabled', function (isDisabled) {
                $scope.isDisabled = isDisabled;
            }, true);

            (function($scope){
                if ($scope.ngModel){
                    $scope.isSelected = true;
                    $scope.selectedRecord = $scope.ngModel;
                }
            })($scope)
        }
    }
})

function callLookupRemoteAction(remoteAction, queryObject, callback) {
    Visualforce.remoting.Manager.invokeAction(
        remoteAction, queryObject,
        function (result, event) {
            callback(result, event);
        }, {
            buffer: false,
            escape: true,
            timeout: 300000
        }
    );
}
