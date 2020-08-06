opportunityDocumentsJS = function () {

    this.selectedOpportunityDocumentIds = [];
    this.documentsListOfItems = [];

    this.initializeDocuments = function () {
        opportunityDocumentsJS.showLoading(true);
        this.selectedOpportunityDocumentIds = [];
        opportunityDocumentsJS.getDocumentsRemote();
    }

    this.getDocumentsRemote = function () {
        
        Visualforce.remoting.Manager.invokeAction(
            window.REMOTE_ACTION_URLS['getDocumentsRemote'],
            function (result, event) {
                opportunityDocumentsJS.showLoading(false);
                if (event.status) {
                    if (!result.hasErrors) {
                        opportunityDocumentsJS.showLoading(true);
                        opportunityDocumentsJS.setProperty('documentsListOfItems', result.data);
                        opportunityDocumentsJS.loadTableData();
                    } else {
                        scope.$apply();
                        Log.fire(resultOpp, '48');
                    }
                } else {
                    scope.$apply();
                    Log.fire(null, '52');
                }
            }, { escape: false, timeout: 120000 }
        );

    }

    this.updateSelectedOpportunityDocumentIds = function (id) {        
        if(this.selectedOpportunityDocumentIds.includes(id.id)){
            index = this.selectedOpportunityDocumentIds.indexOf(id.id);
            if(index > -1){
                this.selectedOpportunityDocumentIds.splice(index);
            }
        } else{
            this.selectedOpportunityDocumentIds.push(id.id);
        }
    }

    this.getSelectedOpportunityDocumentIds = function () {
        return this.selectedOpportunityDocumentIds;
    }

    this.getDocumentsList = function () {
        return this.documentsListOfItems;
    }

    this.validateOpportunityDocuments = function () {

        opportunityDocumentsJS.showLoading(true);
        
        var documentIds = opportunityDocumentsJS.getSelectedOpportunityDocumentIds();

        Visualforce.remoting.Manager.invokeAction(
            window.REMOTE_ACTION_URLS['validateOpportunityDocuments'],
            documentIds,
            function (result, event) {
                opportunityDocumentsJS.showLoading(false);
                if(event.status) {
                    if(!result.hasErrors){
                        Swal.fire({
                            title: 'Show',
                            text: 'Os Documentos da Oportunidade selecionados foram validados com sucesso!',
                            type: 'success',
                            confirmButtonColor: '#3085d6',
                            confirmButtonText: 'Legal!'
                        }).then((result) => {
                            opportunityDocumentsJS.showLoading(true);
                            opportunityDocumentsJS.getDocumentsRemote();
                        });
                    } else {
                        scope.$apply();
                        Log.fire(resultOpp, '48');
                    }
                } else {
                    scope.$apply();
                    Log.fire(null, '52');
                }
            }, { escape: false, timeout: 120000 }
        );
    }

    this.deleteOpportunityDocuments = function () {
        
        opportunityDocumentsJS.showLoading(true);

        var documentIds = opportunityDocumentsJS.getSelectedOpportunityDocumentIds();

        Visualforce.remoting.Manager.invokeAction(
            window.REMOTE_ACTION_URLS['deleteOpportunityDocuments'],
            documentIds,
            function (result, event) {
                opportunityDocumentsJS.showLoading(false);
                if (event.status) {
                    if (!result.hasErrors) {
                        Swal.fire({
                            title: 'Show',
                            text: 'Os Documentos da Oportunidade selecionados foram excluídos com sucesso!',
                            type: 'success',
                            confirmButtonColor: '#3085d6',
                            confirmButtonText: 'Legal!'
                        }).then((result) => {
                            opportunityDocumentsJS.showLoading(true);
                            opportunityDocumentsJS.getDocumentsRemote();
                        });
                    } else {
                        scope.$apply();
                        Log.fire(resultOpp, '80');
                    }
                } else {
                    scope.$apply();
                    Log.fire(null, '84');
                }
            }, { escape: false, timeout: 120000 }
        );

    }

    this.loadTableData = function () {
        
        var htmlToBuild = `
        <table id="documentstable" class="display" style="padding-top:12px">
            <thead>
                <tr>
                    <th style="width:2%;"></th>
                    <th style="width:11%;">Nome da Oportunidade</th>
                    <th style="width:11%;">Status da Oportunidade</th>
                    <th style="width:8%">RTV</th>
                    <th style="width:10%">Gerente Regional</th>
                    <th style="width:10%">Cliente</th>
                    <th style="width:10%">Tipo de documento</th>
                    <th style="width:10%">Responsável</th>
                    <th style="width:8%">Data de criação</th>
                    <th style="width:20%;">Nome do Documento</th>
                </tr>
            </thead>
            <tbody>`;
        
        var tableList = opportunityDocumentsJS.getProperty('documentsListOfItems');
        
        tableList.forEach((listOfItems) => {

            listOfItems.forEach((item) => {

                var onchangeFunction = `onchange="opportunityDocumentsJS.updateSelectedOpportunityDocumentIds(${item.id})"`

                htmlToBuild += `
                <tr>
                    <td>
                        <input type="checkbox" id="${item.id}" ${onchangeFunction}/>
                    </td>
                    <td>
                        <a href="/${item.opportunityId}" target="_blank">${item.opportunityName}</a>
                    </td>
                    <td>${item.opportunityStatus}</td>
                    <td>${item.rtvName}</td>
                    <td>${item.grName}</td>
                    <td>${item.customerName}</td>
                    <td>${item.typeOfDocument}</td>
                    <td>${item.responsibleUserName}</td>
                    <td>${item.createdDate}</td>
                    <td style="word-break:break-all;">
                        <a href="/${item.documentId}" target="_blank">${item.documentName}</a> 
                    </td>
                </tr>
                `;
            });       
        });

        htmlToBuild += `
            </tbody>
            </table>`;

        opportunityDocumentsJS.setElementById('table_container', 'innerHTML', htmlToBuild, false);

        $(document).ready(function () {
            $('[id$="documentstable"]').DataTable({
                ordering: false
            });
        });

        opportunityDocumentsJS.showLoading(false);

    }

    this.setElementById = function (elementId, property, value, isAppending) {
        isAppending ? document.getElementById(elementId)[property] += value : document.getElementById(elementId)[property] = value;
    }

    this.showLoading = function (showLoading) {
        var loadingDiv = $('#main_load');
        if (showLoading) {
            loadingDiv.show();
        } else {
            loadingDiv.hide();
        }
    }

}

opportunityDocumentsJS.instance = null;

opportunityDocumentsJS.showLoading = function (show) {
    opportunityDocumentsJS.getInstance().showLoading(show);
}

opportunityDocumentsJS.getInstance = function () {
    if (this.instance === null) this.instance = new opportunityDocumentsJS();
    return this.instance;
}

opportunityDocumentsJS.init = function () {
    opportunityDocumentsJS.getInstance().initializeDocuments();
}

opportunityDocumentsJS.updateSelectedOpportunityDocumentIds = function (id) {
    opportunityDocumentsJS.getInstance().updateSelectedOpportunityDocumentIds(id);
}

opportunityDocumentsJS.getSelectedOpportunityDocumentIds = function () {
    return opportunityDocumentsJS.getInstance().getSelectedOpportunityDocumentIds();
}

opportunityDocumentsJS.validateOpportunityDocuments = function () {
    opportunityDocumentsJS.getInstance().validateOpportunityDocuments();
}

opportunityDocumentsJS.deleteOpportunityDocuments = function () {
    opportunityDocumentsJS.getInstance().deleteOpportunityDocuments();
}

opportunityDocumentsJS.getDocumentsRemote = function (){
    opportunityDocumentsJS.getInstance().getDocumentsRemote();
}

opportunityDocumentsJS.getDocumentsList = function () {
    return opportunityDocumentsJS.getInstance().getDocumentsList();
}

opportunityDocumentsJS.loadTableData = function () {
    opportunityDocumentsJS.getInstance().loadTableData();
}

opportunityDocumentsJS.setElementById = function (elementId, property, value, isAppending) {
    opportunityDocumentsJS.getInstance().setElementById(elementId, property, value, isAppending);
}

opportunityDocumentsJS.getProperty = function (param) {
    return opportunityDocumentsJS.getInstance()[param];
}

opportunityDocumentsJS.setProperty = function (property, value) {
    opportunityDocumentsJS.getInstance()[property] = value;
}