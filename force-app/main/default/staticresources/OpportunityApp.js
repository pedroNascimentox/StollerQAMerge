(function () {
    var opportunityApp = angular.module('opportunityApp', ['sf-lookup']);

    opportunityApp.controller('OpportunityCtrl', ['$scope', '$http', '$interval', 'sf-lookup', function ($scope, $http, $interval, sflookup) {
        
        $scope.freightTypes = [
            {
                label:'CIF',
                value:'CIF',
                isDefault: true
            }, 
            {
                label:'FOB',
                value:'FOB'
            }
        ]
        
        $scope.currencies = [
            {
                label:'BRL',
                value:'BRL',
                isDefault: true
            }, 
            {
                label:'USD',
                value:'USD'
            }
        ]
        
        $scope.paymentConditions = [
            {
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
        ]
        $scope.expeditions = [
            {
                label: 'Fracionado', 
                value: 'Fracionado',
            	isDefault: true,
            },
            {
                label:'Cotação',
                value:'Cotação'
            }
        ]
        
        $scope.orderTypes = [
            {
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
        ]
        
        $scope.salesClassifications = [
            {
                label: 'Normal', 
                value: 'Normal',
                isDefault: true,
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
            }
        ]
        
        
        $scope.opportunity = {
            
            freightType: $scope.freightTypes.find(a => a.isDefault),
            currency: $scope.currencies.find(a => a.isDefault),
            paymentCondition: $scope.paymentConditions.find(a => a.isDefault),
            expedition: $scope.expeditions.find(a => a.isDefault),
            orderType: $scope.orderTypes.find(a => a.isDefault),                                    
            salesClassification: $scope.salesClassifications.find(a => a.isDefault),
            
        } 
    
       
    }]); 
    
    opportunityApp.controller('SectionCtrl', ['$scope', function($scope){
        
        $scope.isExpanded = true;
        $scope.isHidden = false;
        
        $scope.toggle = function(){
            $scope.isExpanded = !$scope.isExpanded;
            $scope.isHidden = !$scope.isHidden;
        }
        
        $scope.init = function(isToggled){
            isToggled = isToggled == undefined? true : false;
            
            
            $scope.isExpanded = isToggled;
            $scope.isHidden = !isToggled;
             
        }
    }]);
})(); 