import { LightningElement, track, wire } from 'lwc';
import getPermissionSets from '@salesforce/apex/PSLab_PermissionSetExporterController.getPermissionSets';
import exportPermissionSetAsCSV from '@salesforce/apex/PSLab_PermissionSetExporterController.exportPermissionSetAsCSV';
import { permissionDetectorFilterSettings } from "c/psLabCoreUtils";

export default class PSLabPermissionExporter extends LightningElement {
  @track currentStep = '1';
  @track selectedPermissionSet = '';
  @track selectedPermissions = [];
  @track permissionSetOptions = [];
  @track isGenerating = false;
  @track progressValue = 0;
  @track selectedPermissionSetInfo;
  _fileName = '';
  isFileNameValid = true;

  permissionOptions  = [
    { label: "All", value: "All" },
    ...permissionDetectorFilterSettings.permissionOptions
  ];

  @wire(getPermissionSets)
  wiredPermissionSets({ data, error }) {
    if (data) {
      this.permissionSetOptions = data;
    }else if(error){
      console.error(error);
    }
  }

  get isStep1() {
    return this.currentStep === '1';
  }

  get isStep2() {
    return this.currentStep === '2';
  }

  get isStep3() {
    return this.currentStep === '3';
  }

  get isFirstStep() {
    return this.currentStep === '1';
  }

  get permissionSetLabel(){
    return this.permissionSetOptions.find(p => p.value === this.selectedPermissionSet.toString())?.label;
  }

  get permissionSetUrl() {
    return this.selectedPermissionSet
      ? `/lightning/setup/PermSets/page?address=%2F${this.selectedPermissionSet}`
      : '#';
  }

  get assignedUsersUrl() {
    return this.permissionSetOptions.find(p => p.value === this.selectedPermissionSet.toString())?.assignedUsersURL;
  }


  get isDisabled() {
    if (this.isStep1) {
      return !this.selectedPermissionSet
    }
    if (this.isStep2) {
      return this.selectedPermissions.length === 0;
    }
    return this.isStep3;

  }

  get fileName(){
    return this._fileName || this.permissionSetLabel;
  }

  set fileName(value){
    this._fileName = value;
  }



  handlePermissionSelection(event) {
    const newlySelectedValues = event.detail.value;
    const allOptionValue = 'All';

    const allPermissionValues = this.permissionOptions
        .map(option => option.value)
        .filter(value => value !== allOptionValue);

    const allWasPreviouslySelected = this.selectedPermissions?.includes(allOptionValue);
    const allIsNowSelected = newlySelectedValues.includes(allOptionValue);

    if (allIsNowSelected && !allWasPreviouslySelected) {
      this.selectedPermissions = [allOptionValue, ...allPermissionValues];

    } else if (!allIsNowSelected && allWasPreviouslySelected) {
      this.selectedPermissions = [];

    } else if (newlySelectedValues.length === allPermissionValues.length && !allWasPreviouslySelected) {
      this.selectedPermissions = [allOptionValue, ...allPermissionValues];

    } else {
      if (allWasPreviouslySelected) {
        this.selectedPermissions = newlySelectedValues.filter(value => value !== allOptionValue);
      } else {
        this.selectedPermissions = newlySelectedValues;
      }
    }
  }
  handlePermissionSetChange(event) {
    const values = event.detail.values || [];
    this.selectedPermissionSet = values;

    if (values.length === 1) {
      const selected = this.permissionSetOptions.find(p => p.value === values[0]);
      if (selected) {
        this.selectedPermissionSetInfo = {
          description: selected.description || "N/A",
          createdBy: selected.createdBy || "N/A",
          createdDate: selected.createdDate || "N/A",
          lastModifiedBy: selected.lastModifiedBy || "N/A",
          lastModifiedDate: selected.lastModifiedDate || "N/A",
          isCustom: selected.isCustom ? "Custom" : "Standard",
          includedIn: selected.includedIn?.toString() || "N/A",
          type: selected.type || "N/A"
        };
      }
    } else {
      this.selectedPermissionSetInfo = null;
    }
  }


  handleFileNameChange(event) {
    this.fileName = event.detail.value;
    const inputField = this.template.querySelector('.fileNameInput');
    this.isFileNameValid = inputField.checkValidity();
  }

  handleNext() {
    if (this.currentStep === '1') this.currentStep = '2';
    else if (this.currentStep === '2') this.currentStep = '3';
  }

  handlePrevious() {
    if (this.currentStep === '3') this.currentStep = '2';
    else if (this.currentStep === '2') this.currentStep = '1';
  }

  async handleGenerateCSV() {
    this.isGenerating = true;
    this.progressValue = 30; // Start progress
    const csvData = await exportPermissionSetAsCSV({permissionSetId: this.selectedPermissionSet[0], permissions: this.selectedPermissions});

    setTimeout(() => {
      this.progressValue = 70;
      try {
        this.progressValue = 100;
        if (csvData){
          const blob = new Blob([csvData], { type: 'application/octet-stream' });
          const link = document.createElement('a');
          link.href = URL.createObjectURL(blob);
          link.download = (this.fileName || 'report') + '.csv';
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);

          setTimeout(() => {
            this.isGenerating = false;
            this.progressValue = 0;
          }, 500);
        }
      }catch (ex){
        console.error(ex);
        this.isGenerating = false;
        this.progressValue = 0;
      }
    }, 1000);
  }

}