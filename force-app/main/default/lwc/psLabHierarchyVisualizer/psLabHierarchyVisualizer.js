import { LightningElement, track } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import D3 from "@salesforce/resourceUrl/d3";
import getPermissionSetHierarchy from "@salesforce/apex/PSLab_PermissionAnalysisController.getPermissionSetHierarchy";
import { D3Tree } from "./d3Tree";
import { PermissionHierarchyFilter } from "./permissionHierarchyFilter";
import { deepClone, reduceErrors } from "c/psLabCoreUtils";

export default class PSLabHierarchyVisualizer extends LightningElement {
    isLoading = true;
    showSettings = true;
    expansionState = "collapsed";
    showScrollButton = false;

    _chart;
    _filterService = new PermissionHierarchyFilter();
    _originalHierarchyData;
    _contextualHierarchyData;
    _currentHierarchyData;

    get settingsSectionClass() {
        return this.showSettings ? "settings-section settings-visible" : "settings-section settings-hidden";
    }

    get toggleButtonLabel() {
        return this.expansionState === "collapsed" ? "Expand All" : "Collapse All";
    }

    get toggleIcon() {
        return this.showSettings ? "utility:chevronleft" : "utility:chevronright";
    }

    connectedCallback() {
        Promise.all([
            loadScript(this, D3 + "/d3/d3.v7.min.js"),
            getPermissionSetHierarchy()
        ])
            .then(([, data]) => {
                if (data) {
                    this._originalHierarchyData = deepClone(data);
                    this._currentHierarchyData = data;
                } else {
                    this.handleError('Data Error', 'No hierarchy data returned from Apex.');
                }
            })
            .catch((error) => this.handleError('Initialization Failed', error))
            .finally(() => { this.isLoading = false; });
    }

    renderedCallback() {
        if (this._currentHierarchyData && !this._chart) {
            const container = this.template.querySelector(".tree-container");
            if (container) {
                this._chart = new D3Tree(container);
                this._chart.initialize(this._currentHierarchyData);
            }
        }
        if (!this._scrollListener) {
            const container = this.template.querySelector('.tree-container');
            if (container) {
                this._scrollListener = this.handleScroll.bind(this);
                container.addEventListener('scroll', this._scrollListener);
            }
        }
    }

    disconnectedCallback() {
        const container = this.template.querySelector('.tree-container');
        if (this._scrollListener && container) {
            container.removeEventListener('scroll', this._scrollListener);
        }
    }

    toggleSettings() {
        this.showSettings = !this.showSettings;
    }

    handleToggleExpansion() {
        if (!this._chart) {
            return;
        }

        if (this.expansionState === "collapsed") {
            this._chart.expandAll();
            this.expansionState = "expanded";
        } else {
            this._chart.collapseAll();
            this.expansionState = "collapsed";
        }
    }


    handleScroll(event) {
        if (this._chart) {
            this._chart.hideTooltip();
        }
        if (this._debounceTimer) {
            window.clearTimeout(this._debounceTimer);
        }
        const container = event.target;
        this._debounceTimer = window.setTimeout(() => {
            this.showScrollButton = container.scrollTop > 300;
        }, 150);
    }

    handleScrollToTop() {
        const container = this.template.querySelector(".tree-container");
        if (container) {
            container.scrollTo({ top: 0, behavior: 'smooth' });
        }
    }


    handleDetection(event) {
        const { permissionSets, payload } = event.detail;

        if (!this._originalHierarchyData || !permissionSets) {
            return;
        }

        this.isLoading = true;

        const baseHierarchy = this._contextualHierarchyData || this._originalHierarchyData;


        let filteredData;
        let highlightedIds;

        if (Object.keys(payload).length === 0) {
            this._contextualHierarchyData = permissionSets;
            filteredData = permissionSets;
            highlightedIds = this._filterService.collectIds(permissionSets);

        } else {
            const filterResult = this._filterService.filter(
                baseHierarchy,
                permissionSets,
                payload
            );
            filteredData = filterResult.filteredData;
            highlightedIds = filterResult.highlightedIds;
        }

        if (filteredData && filteredData.children && filteredData.children.length > 0) {
            this._chart.update(filteredData, highlightedIds);
            this._chart.expandAll();
            this.expansionState = "expanded";
        } else {
            this.showToast("Info", "No matching items found for the applied filter.", "info");
            this._chart.update(this.getEmptyHierarchy(), new Set());
        }

        this.isLoading = false;
    }

    handleClearContext(){
        this._contextualHierarchyData = null;
    }
    handleFilterReset() {
        this._currentHierarchyData = deepClone(this._originalHierarchyData);
        this._chart.update(this._currentHierarchyData, new Set());
        this.expansionState = "collapsed";
        this.showToast("Info", "Filters Reset. Displaying full hierarchy.", "info");
    }

    getEmptyHierarchy() {
        const emptyRoot = deepClone(this._originalHierarchyData);
        emptyRoot.children = [];
        return emptyRoot;
    }

    showToast(title, message, variant = "info") {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleError(title, error) {
        const message = reduceErrors(error);
        this.showToast(title, message, "error");
        console.error(title, JSON.stringify(error));
    }


}