<div class="slds-grid slds-wrap price-list">

    <!-- INFORMAÇÕES DA COTAÇÃO -->

    <div class="opportunity-section slds-section" ng-class="isExpanded? 'slds-is-open' : ''"
        ng-controller="SectionCtrl">
        <h3 class="slds-section__title">
            <button aria-controls="info-section" aria-expanded="{{isExpanded}}"
                class="slds-button slds-section__title-action" ng-click="toggle()">
                <svg class="slds-section__title-action-icon slds-button__icon slds-button__icon_left"
                    aria-hidden="false">
                    <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#switch">
                    </use>
                </svg>
                <span class="slds-truncate slds-p-horizontal_small" title="Informações da Cotação">Informações da
                    Cotação</span>
            </button>
        </h3>
        <div aria-hidden="{{isHidden}}" class="slds-section__content slds-grid slds-wrap" id="info-section">

            <!-- CLIENTE -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2">

                <div class="slds-form-element">
                    <abbr class="slds-required" title="required">* </abbr> <label class="slds-form-element__label"
                        for="combobox-id-5">Cliente</label>
                    <div class="slds-form-element__control">
                        <div class="slds-combobox_container slds-has-selection">
                            <div class="slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click"
                                aria-expanded="false" aria-haspopup="listbox" role="combobox">
                                <div class="slds-combobox__form-element slds-input-has-icon slds-input-has-icon_left-right"
                                    role="none">
                                    <span
                                        class="slds-icon_container slds-icon-standard-account slds-combobox__input-entity-icon"
                                        title="Account">
                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                            <use
                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                            </use>
                                        </svg>
                                        <span class="slds-assistive-text">Account</span>
                                    </span>
                                    <input type="text"
                                        class="slds-input slds-combobox__input slds-combobox__input-value"
                                        id="combobox-id-5" aria-controls="listbox-id-5" autoComplete="off"
                                        role="textbox" placeholder="Select an Option" readonly=""
                                        value="Cliente - Teste" required="" />
                                    <button class="slds-button slds-button_icon slds-input__icon slds-input__icon_right"
                                        title="Remove selected option">
                                        <svg class="slds-button__icon" aria-hidden="true">
                                            <use
                                                xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#close">
                                            </use>
                                        </svg>
                                        <span class="slds-assistive-text">Remove selected option</span>
                                    </button>
                                </div>
                                <div id="listbox-id-5"
                                    class="slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_fluid"
                                    role="listbox">
                                    <ul class="slds-listbox slds-listbox_vertical" role="presentation">
                                        <li role="presentation" class="slds-listbox__item">
                                            <div id="option1"
                                                class="slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
                                                role="option">
                                                <span class="slds-media__figure slds-listbox__option-icon">
                                                    <span class="slds-icon_container slds-icon-standard-account">
                                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                                            <use
                                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                                            </use>
                                                        </svg>
                                                    </span>
                                                </span>
                                                <span class="slds-media__body">
                                                    <span
                                                        class="slds-listbox__option-text slds-listbox__option-text_entity">Burlington
                                                        Textiles Corp of America</span>
                                                    <span
                                                        class="slds-listbox__option-meta slds-listbox__option-meta_entity">Account
                                                        • Burlington, NC</span>
                                                </span>
                                            </div>
                                        </li>
                                        <li role="presentation" class="slds-listbox__item">
                                            <div id="option2"
                                                class="slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
                                                role="option">
                                                <span class="slds-media__figure slds-listbox__option-icon">
                                                    <span class="slds-icon_container slds-icon-standard-account">
                                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                                            <use
                                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                                            </use>
                                                        </svg>
                                                    </span>
                                                </span>
                                                <span class="slds-media__body">
                                                    <span
                                                        class="slds-listbox__option-text slds-listbox__option-text_entity">Dickenson
                                                        plc</span>
                                                    <span
                                                        class="slds-listbox__option-meta slds-listbox__option-meta_entity">Account
                                                        • Lawrence, KS</span>
                                                </span>
                                            </div>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

            <!-- NUM PEDIDO CLIENTE-->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <label class="slds-form-element__label"
                        for="form-element-01">Número do pedido do cliente</label>
                    <div class="slds-form-element__control">
                        <input type="text" id="text-input-id-1" class="slds-input" />
                    </div>
                </div>
            </div>

            <!-- MOEDA -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <abbr class="slds-required" title="required">* </abbr><label class="slds-form-element__label"
                        for="form-element-01">Moeda</label>
                    <div class="slds-form-element__control">
                        <div class="slds-select_container">
                            <select class="slds-select" id="select-01" ng-model="cart.header.currency"
                                ng-options="option as option.label for option in base.currencies" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- CONDICAO EXPEDICAO -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <abbr class="slds-required" title="required">* </abbr> <label class="slds-form-element__label"
                        for="form-element-01">Condição de expedição</label>
                    <div class="slds-form-element__control">
                        <div class="slds-select_container">
                            <select class="slds-select" id="select-01" ng-model="cart.header.expedition"
                                ng-options="expedition as expedition.label for expedition in base.expeditions" />
                            </select>
                        </div>
                    </div>
                </div>
            </div>

            <!-- TERRITORIO -->
            <!-- <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2">

                <div class="slds-form-element">
                    <abbr class="slds-required" title="required">* </abbr> <label class="slds-form-element__label"
                        for="combobox-id-5">Território</label>
                    <div class="slds-form-element__control">
                        <div class="slds-combobox_container slds-has-selection">
                            <div class="slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click"
                                aria-expanded="false" aria-haspopup="listbox" role="combobox">
                                <div class="slds-combobox__form-element slds-input-has-icon slds-input-has-icon_left-right"
                                    role="none">
                                    <span
                                        class="slds-icon_container slds-icon-standard-account slds-combobox__input-entity-icon"
                                        title="Account">
                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                            <use
                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                            </use>
                                        </svg>
                                        <span class="slds-assistive-text">Account</span>
                                    </span>
                                    <input type="text"
                                        class="slds-input slds-combobox__input slds-combobox__input-value"
                                        id="combobox-id-5" aria-controls="listbox-id-5" autoComplete="off"
                                        role="textbox" placeholder="Select an Option" readonly=""
                                        value="SP / RJ / MG" />
                                    <button class="slds-button slds-button_icon slds-input__icon slds-input__icon_right"
                                        title="Remove selected option">
                                        <svg class="slds-button__icon" aria-hidden="true">
                                            <use
                                                xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#close">
                                            </use>
                                        </svg>
                                        <span class="slds-assistive-text">Remove selected option</span>
                                    </button>
                                </div>
                                <div id="listbox-id-5"
                                    class="slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_fluid"
                                    role="listbox">
                                    <ul class="slds-listbox slds-listbox_vertical" role="presentation">
                                        <li role="presentation" class="slds-listbox__item">
                                            <div id="option1"
                                                class="slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
                                                role="option">
                                                <span class="slds-media__figure slds-listbox__option-icon">
                                                    <span class="slds-icon_container slds-icon-standard-account">
                                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                                            <use
                                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                                            </use>
                                                        </svg>
                                                    </span>
                                                </span>
                                                <span class="slds-media__body">
                                                    <span
                                                        class="slds-listbox__option-text slds-listbox__option-text_entity">Burlington
                                                        Textiles Corp of America</span>
                                                    <span
                                                        class="slds-listbox__option-meta slds-listbox__option-meta_entity">Account
                                                        • Burlington, NC</span>
                                                </span>
                                            </div>
                                        </li>
                                        <li role="presentation" class="slds-listbox__item">
                                            <div id="option2"
                                                class="slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
                                                role="option">
                                                <span class="slds-media__figure slds-listbox__option-icon">
                                                    <span class="slds-icon_container slds-icon-standard-account">
                                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                                            <use
                                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                                            </use>
                                                        </svg>
                                                    </span>
                                                </span>
                                                <span class="slds-media__body">
                                                    <span
                                                        class="slds-listbox__option-text slds-listbox__option-text_entity">Dickenson
                                                        plc</span>
                                                    <span
                                                        class="slds-listbox__option-meta slds-listbox__option-meta_entity">Account
                                                        • Lawrence, KS</span>
                                                </span>
                                            </div>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div> -->

            <!-- TIPO DE FRETE-->
            <!-- <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <abbr class="slds-required" title="required">* </abbr> <label class="slds-form-element__label"
                        for="form-element-01">Tipo de frete</label>
                    <div class="slds-form-element__control">
                        <div class="slds-select_container">
                            <select class="slds-select" id="select-01" ng-model="cart.header.freightType"
                                ng-options="freightType as freightType.label for freightType in base.freightTypes" />
                            </select>
                        </div>
                    </div>
                </div>
            </div> -->
        </div>
    </div>

    <!-- TRATATIVAS -->

    <div class="opportunity-section slds-section" ng-class="isExpanded? 'slds-is-open' : ''" ng-controller="SectionCtrl">
        <h3 class="slds-section__title">
            <button aria-controls="tratativas-section" aria-expanded="{{isExpanded}}"
                class="slds-button slds-section__title-action" ng-click="toggle()">
                <svg class="slds-section__title-action-icon slds-button__icon slds-button__icon_left"
                    aria-hidden="true">
                    <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#switch">
                    </use>
                </svg>
                <span class="slds-truncate slds-p-horizontal_small" title="Tratativas">Tratativas</span>
            </button>
        </h3>
        <div aria-hidden="{{isHidden}}" class="slds-section__content slds-grid slds-wrap" id="tratativas-section">


            <!-- TIPO DE ORDEM -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <abbr class="slds-required" title="required">* </abbr> <label class="slds-form-element__label"
                        for="form-element-01">Tipo de Ordem</label>
                    <div class="slds-form-element__control">
                        <div class="slds-select_container">
                            <select class="slds-select" id="21" ng-model="cart.header.orderType"
                                ng-options="orderType as orderType.label for orderType in base.orderTypes" />
                            </select>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- CLASSIFICAÇÃO DA VENDA -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <label class="slds-form-element__label" for="321">Classificação da Venda</label>
                    <div class="slds-form-element__control">
                        <div class="slds-select_container">
                            <select class="slds-select" ng-model="cart.header.salesClassification"
                                ng-options="salesClassification as salesClassification.label for salesClassification in base.salesClassifications" />
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- CAMPANHA -->

            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2" ng-show="cart.header.salesClassification.isCampaignClassification == true">
                <div class="slds-form-element">
                    <abbr class="slds-required" title="required">* </abbr>
                    <label class="slds-form-element__label" for="combobox-id-5">Campanha</label>
                    <!-- <div class="slds-form-element__control">
                        <div class="slds-combobox_container slds-has-selection">
                            <div class="slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click"
                                aria-expanded="false" aria-haspopup="listbox" role="combobox">
                                <div class="slds-combobox__form-element slds-input-has-icon slds-input-has-icon_left-right"
                                    role="none">
                                    <span
                                        class="slds-icon_container slds-icon-standard-account slds-combobox__input-entity-icon"
                                        title="Account">
                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                            <use
                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                            </use>
                                        </svg>
                                        <span class="slds-assistive-text">Account</span>
                                    </span>
                                    <input type="text"
                                        class="slds-input slds-combobox__input slds-combobox__input-value"
                                        id="combobox-id-5" aria-controls="listbox-id-5" autoComplete="off"
                                        role="textbox" placeholder="Select an Option" readonly=""
                                        value="Agenciador Teste 1" />
                                    <button class="slds-button slds-button_icon slds-input__icon slds-input__icon_right"
                                        title="Remove selected option">
                                        <svg class="slds-button__icon" aria-hidden="true">
                                            <use
                                                xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#close">
                                            </use>
                                        </svg>
                                        <span class="slds-assistive-text">Remove selected option</span>
                                    </button>
                                </div>
                                <div id="listbox-id-5"
                                    class="slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_fluid"
                                    role="listbox">
                                    <ul class="slds-listbox slds-listbox_vertical" role="presentation">
                                        <li role="presentation" class="slds-listbox__item">
                                            <div id="option1"
                                                class="slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
                                                role="option">
                                                <span class="slds-media__figure slds-listbox__option-icon">
                                                    <span class="slds-icon_container slds-icon-standard-account">
                                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                                            <use
                                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                                            </use>
                                                        </svg>
                                                    </span>
                                                </span>
                                                <span class="slds-media__body">
                                                    <span
                                                        class="slds-listbox__option-text slds-listbox__option-text_entity">Burlington
                                                        Textiles Corp of America</span>
                                                    <span
                                                        class="slds-listbox__option-meta slds-listbox__option-meta_entity">Account
                                                        • Burlington, NC</span>
                                                </span>
                                            </div>
                                        </li>
                                        <li role="presentation" class="slds-listbox__item">
                                            <div id="option2"
                                                class="slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
                                                role="option">
                                                <span class="slds-media__figure slds-listbox__option-icon">
                                                    <span class="slds-icon_container slds-icon-standard-account">
                                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                                            <use
                                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                                            </use>
                                                        </svg>
                                                    </span>
                                                </span>
                                                <span class="slds-media__body">
                                                    <span
                                                        class="slds-listbox__option-text slds-listbox__option-text_entity">Dickenson
                                                        plc</span>
                                                    <span
                                                        class="slds-listbox__option-meta slds-listbox__option-meta_entity">Account
                                                        • Lawrence, KS</span>
                                                </span>
                                            </div>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div> -->
                </div>
            </div>
            
            

            <!-- CONDIÇÃO DE PAGAMENTO -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <label class="slds-form-element__label" for="form-element-01">Condição de pagamento</label>
                    <div class="slds-form-element__control">
                        <div class="slds-select_container">
                            <select class="slds-select" id="31" ng-model="cart.header.paymentCondition"
                                ng-options="paymentCondition as paymentCondition.label for paymentCondition in base.paymentConditions" />
                            </select>
                        </div>
                    </div>
                </div>
            </div>

            <!-- VENCIMENTO VENDOR -->
            <!-- <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <label class="slds-form-element__label" for="form-element-01">Vencimento vendor</label>
                    <div class="slds-form-element__control">
                        <input type="date" id="text-input-id-1" class="slds-input" />
                    </div>
                </div>
            </div> -->

            <!-- MOTIVO DA ORDEM -->
            <!-- <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-1 ">
                <div class="slds-form-element">
                    <label class="slds-form-element__label" for="form-element-01">Motivo da ordem</label>
                    <div class="slds-form-element__control">
                        <input type="text" id="text-input-id-1" class="slds-input" />
                    </div>
                </div>
            </div> -->

            <!-- AGENCIAMENTO APLICADO -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <div class="slds-form-element__control">
                        <div class="slds-checkbox">
                            <input type="checkbox" id="checkbox-id-01" name="label" value="option"
                                ng-model="cart.header.isAgencied" checked="" />
                            <label class="slds-checkbox__label" for="checkbox-id-01">
                                <span class="slds-checkbox_faux"></span>
                                <span class="slds-form-element__label">Agenciamento aplicado</span>
                            </label>
                        </div>
                    </div>
                </div>
            </div>

            <!-- AGENCIADOR -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2" ng-show="cart.header.isAgencied == true"
                required="true">

                <div class="slds-form-element">
                    <abbr class="slds-required" title="required">* </abbr> <label class="slds-form-element__label"
                        for="combobox-id-5">Agenciador</label>
                    <div class="slds-form-element__control">
                        <div class="slds-combobox_container slds-has-selection">
                            <div class="slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click"
                                aria-expanded="false" aria-haspopup="listbox" role="combobox">
                                <div class="slds-combobox__form-element slds-input-has-icon slds-input-has-icon_left-right"
                                    role="none">
                                    <span
                                        class="slds-icon_container slds-icon-standard-account slds-combobox__input-entity-icon"
                                        title="Account">
                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                            <use
                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                            </use>
                                        </svg>
                                        <span class="slds-assistive-text">Account</span>
                                    </span>
                                    <input type="text"
                                        class="slds-input slds-combobox__input slds-combobox__input-value"
                                        id="combobox-id-5" aria-controls="listbox-id-5" autoComplete="off"
                                        role="textbox" placeholder="Select an Option" readonly=""
                                        value="Agenciador Teste 1" />
                                    <button class="slds-button slds-button_icon slds-input__icon slds-input__icon_right"
                                        title="Remove selected option">
                                        <svg class="slds-button__icon" aria-hidden="true">
                                            <use
                                                xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#close">
                                            </use>
                                        </svg>
                                        <span class="slds-assistive-text">Remove selected option</span>
                                    </button>
                                </div>
                                <div id="listbox-id-5"
                                    class="slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_fluid"
                                    role="listbox">
                                    <ul class="slds-listbox slds-listbox_vertical" role="presentation">
                                        <li role="presentation" class="slds-listbox__item">
                                            <div id="option1"
                                                class="slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
                                                role="option">
                                                <span class="slds-media__figure slds-listbox__option-icon">
                                                    <span class="slds-icon_container slds-icon-standard-account">
                                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                                            <use
                                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                                            </use>
                                                        </svg>
                                                    </span>
                                                </span>
                                                <span class="slds-media__body">
                                                    <span
                                                        class="slds-listbox__option-text slds-listbox__option-text_entity">Burlington
                                                        Textiles Corp of America</span>
                                                    <span
                                                        class="slds-listbox__option-meta slds-listbox__option-meta_entity">Account
                                                        • Burlington, NC</span>
                                                </span>
                                            </div>
                                        </li>
                                        <li role="presentation" class="slds-listbox__item">
                                            <div id="option2"
                                                class="slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
                                                role="option">
                                                <span class="slds-media__figure slds-listbox__option-icon">
                                                    <span class="slds-icon_container slds-icon-standard-account">
                                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                                            <use
                                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                                            </use>
                                                        </svg>
                                                    </span>
                                                </span>
                                                <span class="slds-media__body">
                                                    <span
                                                        class="slds-listbox__option-text slds-listbox__option-text_entity">Dickenson
                                                        plc</span>
                                                    <span
                                                        class="slds-listbox__option-meta slds-listbox__option-meta_entity">Account
                                                        • Lawrence, KS</span>
                                                </span>
                                            </div>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

            <!-- RECEBEDOR DA MERCADORIA -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2">

                <div class="slds-form-element">
                    <label class="slds-form-element__label" for="combobox-id-5">Recebedor da Mercadoria</label>
                    <div class="slds-form-element__control">
                        <div class="slds-combobox_container slds-has-selection">
                            <div class="slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click"
                                aria-expanded="false" aria-haspopup="listbox" role="combobox">
                                <div class="slds-combobox__form-element slds-input-has-icon slds-input-has-icon_left-right"
                                    role="none">
                                    <span
                                        class="slds-icon_container slds-icon-standard-account slds-combobox__input-entity-icon"
                                        title="Account">
                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                            <use
                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                            </use>
                                        </svg>
                                        <span class="slds-assistive-text">Account</span>
                                    </span>
                                    <input type="text"
                                        class="slds-input slds-combobox__input slds-combobox__input-value"
                                        id="combobox-id-5" aria-controls="listbox-id-5" autoComplete="off"
                                        role="textbox" placeholder="Select an Option" readonly=""
                                        value="CLIENTE - 1 - TESTE" />
                                    <button class="slds-button slds-button_icon slds-input__icon slds-input__icon_right"
                                        title="Remove selected option">
                                        <svg class="slds-button__icon" aria-hidden="true">
                                            <use
                                                xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#close">
                                            </use>
                                        </svg>
                                        <span class="slds-assistive-text">Remove selected option</span>
                                    </button>
                                </div>
                                <div id="listbox-id-5"
                                    class="slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_fluid"
                                    role="listbox">
                                    <ul class="slds-listbox slds-listbox_vertical" role="presentation">
                                        <li role="presentation" class="slds-listbox__item">
                                            <div id="option1"
                                                class="slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
                                                role="option">
                                                <span class="slds-media__figure slds-listbox__option-icon">
                                                    <span class="slds-icon_container slds-icon-standard-account">
                                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                                            <use
                                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                                            </use>
                                                        </svg>
                                                    </span>
                                                </span>
                                                <span class="slds-media__body">
                                                    <span
                                                        class="slds-listbox__option-text slds-listbox__option-text_entity">Burlington
                                                        Textiles Corp of America</span>
                                                    <span
                                                        class="slds-listbox__option-meta slds-listbox__option-meta_entity">Account
                                                        • Burlington, NC</span>
                                                </span>
                                            </div>
                                        </li>
                                        <li role="presentation" class="slds-listbox__item">
                                            <div id="option2"
                                                class="slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
                                                role="option">
                                                <span class="slds-media__figure slds-listbox__option-icon">
                                                    <span class="slds-icon_container slds-icon-standard-account">
                                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                                            <use
                                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                                            </use>
                                                        </svg>
                                                    </span>
                                                </span>
                                                <span class="slds-media__body">
                                                    <span
                                                        class="slds-listbox__option-text slds-listbox__option-text_entity">Dickenson
                                                        plc</span>
                                                    <span
                                                        class="slds-listbox__option-meta slds-listbox__option-meta_entity">Account
                                                        • Lawrence, KS</span>
                                                </span>
                                            </div>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

            <!-- CLIENTE EMISSOR -->
            <!-- <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2">

                <div class="slds-form-element">
                    <label class="slds-form-element__label" for="combobox-id-5">Cliente Emissor</label>
                    <div class="slds-form-element__control">
                        <div class="slds-combobox_container slds-has-selection">
                            <div class="slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click"
                                aria-expanded="false" aria-haspopup="listbox" role="combobox">
                                <div class="slds-combobox__form-element slds-input-has-icon slds-input-has-icon_left-right"
                                    role="none">
                                    <span
                                        class="slds-icon_container slds-icon-standard-account slds-combobox__input-entity-icon"
                                        title="Account">
                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                            <use
                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                            </use>
                                        </svg>
                                        <span class="slds-assistive-text">Account</span>
                                    </span>
                                    <input type="text"
                                        class="slds-input slds-combobox__input slds-combobox__input-value"
                                        id="combobox-id-5" aria-controls="listbox-id-5" autoComplete="off"
                                        role="textbox" placeholder="Select an Option" readonly=""
                                        value="CLIENTE - 1 - EMISSOR" />
                                    <button class="slds-button slds-button_icon slds-input__icon slds-input__icon_right"
                                        title="Remove selected option">
                                        <svg class="slds-button__icon" aria-hidden="true">
                                            <use
                                                xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#close">
                                            </use>
                                        </svg>
                                        <span class="slds-assistive-text">Remove selected option</span>
                                    </button>
                                </div>
                                <div id="listbox-id-5"
                                    class="slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_fluid"
                                    role="listbox">
                                    <ul class="slds-listbox slds-listbox_vertical" role="presentation">
                                        <li role="presentation" class="slds-listbox__item">
                                            <div id="option1"
                                                class="slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
                                                role="option">
                                                <span class="slds-media__figure slds-listbox__option-icon">
                                                    <span class="slds-icon_container slds-icon-standard-account">
                                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                                            <use
                                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                                            </use>
                                                        </svg>
                                                    </span>
                                                </span>
                                                <span class="slds-media__body">
                                                    <span
                                                        class="slds-listbox__option-text slds-listbox__option-text_entity">Burlington
                                                        Textiles Corp of America</span>
                                                    <span
                                                        class="slds-listbox__option-meta slds-listbox__option-meta_entity">Account
                                                        • Burlington, NC</span>
                                                </span>
                                            </div>
                                        </li>
                                        <li role="presentation" class="slds-listbox__item">
                                            <div id="option2"
                                                class="slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta"
                                                role="option">
                                                <span class="slds-media__figure slds-listbox__option-icon">
                                                    <span class="slds-icon_container slds-icon-standard-account">
                                                        <svg class="slds-icon slds-icon_small" aria-hidden="true">
                                                            <use
                                                                xlink:href="/apexpages/slds/latest/assets/icons/standard-sprite/svg/symbols.svg#account">
                                                            </use>
                                                        </svg>
                                                    </span>
                                                </span>
                                                <span class="slds-media__body">
                                                    <span
                                                        class="slds-listbox__option-text slds-listbox__option-text_entity">Dickenson
                                                        plc</span>
                                                    <span
                                                        class="slds-listbox__option-meta slds-listbox__option-meta_entity">Account
                                                        • Lawrence, KS</span>
                                                </span>
                                            </div>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div> -->
        </div>
    </div>

    <!-- OBSERVAÇÕES -->

    <div class="opportunity-section slds-section" ng-class="isExpanded? 'slds-is-open' : ''"
        ng-controller="SectionCtrl" ng-init="init(false)">
        <h3 class="slds-section__title">
            <button aria-controls="obs-section" aria-expanded="{{isExpanded}}"
                class="slds-button slds-section__title-action" ng-click="toggle()">
                <svg class="slds-section__title-action-icon slds-button__icon slds-button__icon_left"
                    aria-hidden="true">
                    <use xlink:href="/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#switch">
                    </use>
                </svg>
                <span class="slds-truncate slds-p-horizontal_small" title="Observações">Observações</span>
            </button>
        </h3>
        <div aria-hidden="{{isHidden}}" class="slds-section__content slds-grid slds-wrap" id="obs-section">
            <!-- OBSERVAÇÃO INTERNA -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <label class="slds-form-element__label" for="form-element-01">Observação interna</label>
                    <div class="slds-form-element__control">
                        <textarea rows="3" type="text" id="text-input-id-1" class="slds-input"></textarea>
                    </div>
                </div>
            </div>

            <!-- OBSERVAÇÃO LOGÍSTICA -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <label class="slds-form-element__label" for="form-element-01">Observação logística</label>
                    <div class="slds-form-element__control">
                        <textarea rows="3" type="text" id="text-input-id-1" class="slds-input"></textarea>
                    </div>
                </div>
            </div>

            <!-- OBSERVAÇÃO IMPRESSA PDF -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <label class="slds-form-element__label" for="form-element-01">Observação impressa</label>
                    <div class="slds-form-element__control">
                        <textarea rows="3" type="text" id="text-input-id-1" class="slds-input"></textarea>
                    </div>
                </div>
            </div>

            <!-- OBSERVAÇÃO IMPRESSA NF -->
            <div class="slds-col slds-size_1-of-1 slds-large-size_1-of-2 ">
                <div class="slds-form-element">
                    <label class="slds-form-element__label" for="form-element-01">Observação impressa NF</label>
                    <div class="slds-form-element__control">
                        <textarea rows="3" type="text" id="text-input-id-1" class="slds-input"></textarea>
                    </div>
                </div>
            </div>
        </div>
    </div>

</div>