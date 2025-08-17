import { LightningElement, api, track } from "lwc";

export default class PsLabMultiSelectComboBox extends LightningElement {
  _options = [];

  @track selectedValues = [];
  searchTerm = '';
  showDropdown = false;

  @api label = '';
  @api showSpinner = false;
  @api name = '';
  @api required = false;
  @api isMultiSelect;

  get options() {
    return this._options;
  }

  @api
  set options(options) {
    this._options = options;
  }

  @api
  get value() {
    return this.selectedValues;
  }

  set value(val) {
    console.log(val);
    if (Array.isArray(val)) {
      this.selectedValues = val;
    } else if (val) {
      this.selectedValues = [val];
    } else {
      this.selectedValues = [];
    }
  }

  connectedCallback() {
    document.addEventListener('click', this.handleOutsideClick);
  }

  disconnectedCallback() {
    document.removeEventListener('click', this.handleOutsideClick);
  }

  handleOutsideClick = () => {
    this.showDropdown = false;
  };

  stopPropagation(event) {
    event.stopPropagation();
  }

  get selectedOptions() {
    return this.options.filter(opt => this.selectedValues.includes(opt.value));
  }

  get filteredOptions() {
    const lower = this.searchTerm.toLowerCase();
    return this.options.filter(
      opt =>
        opt.label.toLowerCase().includes(lower) &&
        (!this.isMultiSelect || !this.selectedValues.includes(opt.value))
    );
  }

  get computedInputValue() {
    if (this.isMultiSelect) {
      return this.searchTerm;
    }
    if (this.searchTerm) {
      return this.searchTerm;
    }
    const selected = this.selectedOptions[0];
    return selected ? selected.label : '';
  }

  get noOptions() {
    return this.filteredOptions.length === 0;
  }

  handleInput(event) {
    this.searchTerm = event.target.value;
    this.showDropdown = true;
  }

  openDropdown() {
    this.showDropdown = true;
  }

  toggleDropdown() {
    this.showDropdown = !this.showDropdown;
  }

  handleSelect(event) {
    const value = event.currentTarget.dataset.value;

    if (this.isMultiSelect) {
      if (!this.selectedValues.includes(value)) {
        this.selectedValues = [...this.selectedValues, value];
      }
    } else {
      this.selectedValues = [value];
    }

    this.dispatchEvent(new CustomEvent('change', {
      detail: { values: this.selectedValues }
    }));

    this.searchTerm = '';
    this.showDropdown = false;
  }

  handleRemove(event) {
    const value = event.currentTarget.dataset.value;
    this.selectedValues = this.selectedValues.filter(v => v !== value);

    this.dispatchEvent(new CustomEvent('change', {
      detail: { values: this.selectedValues }
    }));
  }
}