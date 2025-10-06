export class ModDataTree {

    static HAS_CHILDREN_MARKER = '▸';
    static CHILDLESS_MARKER = '•';

    static CRITERIA_LABEL = {
        ALL: {
            key: `all`,
            labelText: taggedString.modDataTreeLabelAll(),
        },
        PATH: {
            key: 'path',
            labelText: taggedString.modDataTreeLabelPath(),
        },
        CREATOR: {
            key: 'creator',
            labelText: taggedString.modDataTreeLabelCreator(),
        },
        MODIFIER_LIST: {
            key: 'modifier',
            labelText: taggedString.modDataTreeLabelModifier(),
        },
        VALUE: {
            key: 'value',
            labelText: taggedString.modDataTreeLabelValue(),
        },
        MOD_COUNT: {
            key: 'modCount',
            labelText: taggedString.modDataTreeLabelModCount(),
        },
        ORDER_DESC: '↓',
        ORDER_ASC: '↑'
    };
    static INFO_KEY_LIST = [
        ModDataTree.CRITERIA_LABEL.CREATOR,
        ModDataTree.CRITERIA_LABEL.MODIFIER_LIST,
        ModDataTree.CRITERIA_LABEL.VALUE,
        ModDataTree.CRITERIA_LABEL.PATH,
    ];
    static CRITERIA_SINGLE = [
        ModDataTree.CRITERIA_LABEL.PATH,
        ModDataTree.CRITERIA_LABEL.CREATOR,
        ModDataTree.CRITERIA_LABEL.MODIFIER_LIST,
        ModDataTree.CRITERIA_LABEL.VALUE,
    ];
    static SORT_CRITERIA = [
        ModDataTree.CRITERIA_LABEL.PATH,
        ModDataTree.CRITERIA_LABEL.CREATOR,
        ModDataTree.CRITERIA_LABEL.MODIFIER_LIST,
        ModDataTree.CRITERIA_LABEL.VALUE,
        ModDataTree.CRITERIA_LABEL.MOD_COUNT,
    ];

    constructor(input) {
        const { overlay, modData, modHistory, } = input;
        this.divOuter = Shared.createHTMLComponent({ class: 'base_mod-data-tree_outer', }).component;
        const { component: divInner, } =
            Shared.createHTMLComponent({ class: 'base_mod-data-tree_inner', parent: this.divOuter, });

        // Add an outer div to solve the row expanding to grid height issue
        const { component: divInfoPanelOuter, } = Shared.createHTMLComponent({
            class: 'base_mod-data-tree_info-panel-outer',
            parent: this.divOuter,
        });

        // this will be the grid contain rows to display node values
        const { component: divInfoPanel, } = Shared.createHTMLComponent({
            class: 'base_mod-data-tree_info-panel',
            parent: divInfoPanelOuter,
        });
        const { infoRowList, } = this.addInfoRow({ parent: divInfoPanel, });
        this.infoRowList = infoRowList;

        // --- Search UI ---
        this.createSearchUI({ parent: divInfoPanelOuter, });

        // Create a button container
        const { component: buttonContainer, } = Shared.createHTMLComponent({
            class: 'base_mod-data-tree_bottom-button-container',
            parent: this.divOuter,
        });
        // Create close button
        const { component: closeBtn, } =
            Shared.createHTMLComponent({ tag: 'button', class: 'base_mod-data-tree_close', parent: buttonContainer, });
        closeBtn.textContent = taggedString.modDataTreeLabelCloseButton();

        // Closing logic
        closeBtn.addEventListener('click', () => {
            overlay.hide();
        });

        // Render the modHistory tree
        if (modHistory) {
            this.renderTree({ modHistory, divParent: divInner, modData, });
        }
    }

    addInfoRow(input) {
        const infoRowList = {};
        ModDataTree.INFO_KEY_LIST.forEach(item => {
            const { key, labelText } = item;
            const { component: infoRow, } = Shared.createHTMLComponent({ class: 'info-row', parent: input.parent });

            const { component: infoLabel, } = Shared.createHTMLComponent({ class: 'info-label', parent: infoRow });
            infoLabel.innerText = labelText;
            if (key == ModDataTree.CRITERIA_LABEL.MODIFIER_LIST.key) {
                infoLabel.innerText = taggedString.modDataTreeLabelLastModifiers();
            }

            const { component: infoValue, } = Shared.createHTMLComponent({ class: 'info-value', parent: infoRow });
            infoValue.innerHTML = input[key] || '';

            // Save reference for later update
            infoRowList[key] = infoValue;
        });
        return { infoRowList, };
    }

    renderTree(input) {
        const { divParent, modHistory, modData } = input;
        for (const rootKey of Object.keys(modHistory)) {
            const { node: nodeEl, } = this.renderNode({
                key: rootKey,
                node: modHistory[rootKey],
                pathSoFar: rootKey,
                modData
            });
            divParent.appendChild(nodeEl);
        }
    }

    renderNode(input) {
        const { key, node, pathSoFar, modData, depth = 0, } = input;
        const { container: details, } = this.createNodeContainer({ depth, });
        const { summary, hasChildren, modifiers, } = this.createSummary({ details, pathSoFar, node, modData, });
        this.attachSummaryEvents({ summary, details, modifiers, });
        this.createMarkerAndLabel({ summary, key, hasChildren, });
        this.renderChildren({ details, node, pathSoFar, modData, depth, });
        return { node: details, };
    }

    createNodeContainer(input) {
        const { component: details, } = Shared.createHTMLComponent({ tag: 'details' });
        details.classList.add(`depth-bg-${input.depth % 4}`);
        return { container: details, };
    }

    createSummary(input) {
        const { details, pathSoFar, node, modData } = input;
        const creator = node.history?.[0] ?? '';
        const modifiers = (node.history ?? []).slice(1).reverse();
        const hasChildren = node.children && Object.keys(node.children).length > 0;

        const { component: summary, } = Shared.createHTMLComponent({ tag: 'summary', parent: details });
        summary.dataset[ModDataTree.CRITERIA_LABEL.PATH.key] = pathSoFar;
        summary.dataset[ModDataTree.CRITERIA_LABEL.CREATOR.key] = creator;
        summary.dataset[ModDataTree.CRITERIA_LABEL.MODIFIER_LIST.key] = modifiers.length ? modifiers.join(', ') : '';
        summary.dataset[ModDataTree.CRITERIA_LABEL.VALUE.key] = '';

        if (!hasChildren) {
            const { current: value, } =
                window.GameClasses.DataLoader.getModDataValue({ modData, pathString: pathSoFar });
            let displayText;
            if (value === null || value === undefined) displayText = '';
            else if (Array.isArray(value)) displayText = `[${value.join(', ')}]`;
            else if (typeof value === 'object') displayText = '';
            else displayText = String(value);

            summary.dataset[ModDataTree.CRITERIA_LABEL.VALUE.key] = displayText;
        }
        return { summary, hasChildren, modifiers, };
    }

    updateInfoPanel(input) {
        const { summary, modifiers, } = input;
        for (let { key } of ModDataTree.INFO_KEY_LIST) {
            this.infoRowList[key].innerText = summary.dataset[key];

            if (key === ModDataTree.CRITERIA_LABEL.MODIFIER_LIST.key) {
                if (modifiers.length < 1) {
                    this.infoRowList[key].innerText = taggedString.modDataTreeLabelNoModifier();
                }
            }
        }
    }

    addClickAndDblClick(input) {
        const { summary, onClick, onDblClick, delay = 200 } = input;
        let timer = null;

        summary.addEventListener('click', (e) => {
            e.stopPropagation();
            e.preventDefault();
            if (timer) return;

            timer = setTimeout(() => {
                timer = null;
                onClick(e);
            }, delay);
        });

        summary.addEventListener('dblclick', (e) => {
            e.stopPropagation();
            if (timer) {
                clearTimeout(timer);
                timer = null;
            }
            onDblClick(e);
        });
    }

    attachSummaryEvents(input) {
        const { summary, details, modifiers } = input;

        this.addClickAndDblClick({
            summary,
            onClick: () => {
                details.open = !details.open;
                this.updateInfoPanel({ summary, modifiers });
            },
            onDblClick: () => {
                const expand = !details.open;
                this.toggleRecursive({ details, expand });
            }
        });
    }

    createMarkerAndLabel(input) {
        const { summary, key, hasChildren, } = input;
        const { component: markerSpan, } = Shared.createHTMLComponent({
            tag: 'span',
            parent: summary,
            class: hasChildren ? 'node-marker-parent' : 'node-marker-leaf'
        });
        markerSpan.textContent = hasChildren ? ModDataTree.HAS_CHILDREN_MARKER : ModDataTree.CHILDLESS_MARKER;
        markerSpan.style.marginRight = '6px';
        markerSpan.style.display = 'inline-block';

        const { component: labelSpan, } = Shared.createHTMLComponent({
            tag: 'span',
            parent: summary,
            class: 'label'
        });
        labelSpan.textContent = key;
    }

    renderChildren(input) {
        const { details, node, pathSoFar, modData, depth, } = input;
        if (!node.children || Object.keys(node.children).length === 0) return;

        const { component: ul, } = Shared.createHTMLComponent({ tag: 'ul', parent: details });
        for (const childKey of Object.keys(node.children)) {
            const { component: li, } = Shared.createHTMLComponent({ tag: 'li', parent: ul });
            const childPath = `${pathSoFar}.${childKey}`;
            const { node: childNode, } = this.renderNode({
                key: childKey,
                node: node.children[childKey],
                pathSoFar: childPath,
                modData,
                depth: depth + 1,
            });
            li.appendChild(childNode);
        }
    }

    toggleRecursive(input) {
        const { details, expand, } = input;
        // Open/close this node
        details.open = expand;
        // Recursively apply to all child <details>
        details.querySelectorAll("details").forEach(child => {
            child.open = expand;
        });
    }

    createSearchUI(input) {
        const parent = input.parent;
        this.createSearchInput({ parent, });
        this.createSearchCriteria({ parent, });
        this.createSortUI({ parent, });
        this.createSearchSummaryUI({ parent, });
        this.createSearchResultContainer({ parent, });
        this.setupSearchListeners();
    }

    createSearchSummaryUI(input) {
        const { component, } = Shared.createHTMLComponent({
            class: 'base_mod-data-tree_result-summary',
            parent: input.parent,
        });
        this.divResultSummary = component;
    }

    createSearchInput(input) {
        const { component: searchInput, } = Shared.createHTMLComponent({
            class: 'base_mod-data-tree_search-outer',
            parent: input.parent,
        });
        this.inputSearch = Shared.createHTMLComponent({
            tag: 'input',
            class: 'base_mod-data-tree_search-input',
            id: 'inputSearch',
            parent: searchInput,
        }).component;
        this.inputSearch.placeholder = taggedString.modDataTreeLabelSearchPlaceholder();
        return { searchInput, };
    }

    createSearchCriteria(input) {
        this.cbSearchCriteria = {};
        const { component: searchCriteria, } = Shared.createHTMLComponent({
            class: 'base_mod-data-tree_criteria-outer',
            parent: input.parent,
        });

        const { component: rowAll, } = Shared.createHTMLComponent({
            class: 'base_mod-data-tree_criteria-item-all', parent: searchCriteria,
        });
        const cbAllId = ModDataTree.CRITERIA_LABEL.ALL.key;
        this.cbSearchCriteria[cbAllId] = Shared.createHTMLComponent({
            tag: 'input',
            type: 'checkbox',
            id: cbAllId,
            parent: rowAll
        }).component;
        const { component: allLabel, } = Shared.createHTMLComponent({ tag: 'label', parent: rowAll });
        allLabel.textContent = ModDataTree.CRITERIA_LABEL.ALL.labelText;
        allLabel.setAttribute('for', cbAllId);

        const cbSingleList = [];

        ModDataTree.CRITERIA_SINGLE.forEach(item => {
            const { key, labelText, } = item;
            const { component: className, } = `base_mod-data-tree_criteria-item-${key.toLowerCase()}`;
            const { component: rowGrid, } = Shared.createHTMLComponent({ class: className, parent: searchCriteria, });
            const id = `cbSearch${key}`;
            const { component: checkbox, } = Shared.createHTMLComponent({ tag: 'input', type: 'checkbox', id, parent: rowGrid });
            this.cbSearchCriteria[key] = checkbox;
            cbSingleList.push(checkbox);
            const { component: label, } = Shared.createHTMLComponent({ tag: 'label', parent: rowGrid });
            label.textContent = labelText;
            label.setAttribute('for', id);
        });
        this.setupSearchCheckboxes({ cbAll: this.cbSearchCriteria[cbAllId], cbSingleList, });
        return { searchCriteria, };
    }

    setupSearchCheckboxes(input) {
        const initState = true;
        const { cbAll, cbSingleList } = input;
        let isUpdating = false; // <-- flag

        // When "All" is clicked
        cbAll.addEventListener('change', () => {
            isUpdating = true; // mark programmatic update
            const checked = cbAll.checked;
            cbSingleList.forEach(cb => cb.checked = checked);
            isUpdating = false; // reset flag
        });

        // When any single checkbox changes, update "All"
        cbSingleList.forEach(cb => {
            cb.checked = initState;
            cb.addEventListener('change', () => {
                if (isUpdating) return; // skip if programmatic
                cbAll.checked = cbSingleList.every(cb => cb.checked);
            });
        });
        cbAll.checked = initState;
    }

    createSearchResultContainer(input) {
        const parent = input.parent;
        const { component: divOuter, } = Shared.createHTMLComponent({
            class: 'base_mod-data-tree_result-outer',
            parent,
        });
        this.divResultInner = Shared.createHTMLComponent({
            class: 'base_mod-data-tree_result-inner',
            parent: divOuter,
        }).component;
    }

    createSortUI(input) {
        const parent = input.parent;
        const { component: divSortOuter, } = Shared.createHTMLComponent({
            class: 'base_mod-data-tree_sort-outer',
            parent,
        });

        const { component: labelSortBy, } = Shared.createHTMLComponent({
            tag: 'label',
            class: 'base_mod-data-tree_sort-label',
            parent: divSortOuter,
        });
        labelSortBy.textContent = taggedString.modDataTreeLabelSortBy();

        this.selectSortCriteria = Shared.createHTMLComponent({
            tag: 'select',
            class: 'base_mod-data-tree_sort-select',
            parent: divSortOuter,
        }).component;

        ModDataTree.SORT_CRITERIA.forEach(item => {
            const { key, labelText, } = item;
            const option = document.createElement('option');
            option.value = key;
            option.textContent = labelText;
            this.selectSortCriteria.appendChild(option);
        });
        this.selectSortCriteria.value = ModDataTree.SORT_CRITERIA[0].key;

        const { component: labelOrder, } = Shared.createHTMLComponent({
            tag: 'label',
            class: 'base_mod-data-tree_sort-label',
            parent: divSortOuter,
        });
        labelOrder.textContent = taggedString.modDataTreeLabelOrder();

        this.selectSortOrder = Shared.createHTMLComponent({
            tag: 'select',
            class: 'base_mod-data-tree_sort-select',
            parent: divSortOuter,
        }).component;

        const sortOrderList = [
            ModDataTree.CRITERIA_LABEL.ORDER_DESC,
            ModDataTree.CRITERIA_LABEL.ORDER_ASC,
        ];
        sortOrderList.forEach(optText => {
            const option = document.createElement('option');
            option.value = optText.toLowerCase();
            option.textContent = optText;
            this.selectSortOrder.appendChild(option);
        });
        this.selectSortOrder.value = sortOrderList[0];
    }

    createSearchResultRow(input) {
        const { parent, result, path, } = input;
        const { component: divResult, } = Shared.createHTMLComponent({
            class: 'base_mod-data-tree_info-panel search-result',
            parent,
        });
        const infoRowInput = { ...result, parent: divResult, };
        this.addInfoRow(infoRowInput);
        // Double-click handler 
        divResult.addEventListener('dblclick', () => {
            this.expandPathToNode({ path, });
        });

        return { searchResultRow: divResult, };
    }

    populateDivResult(input) {
        const { parent, resultList, searchTerm } = input;

        const text = taggedString.modDataTreeLabelSearchSummary(resultList.length, searchTerm);
        this.divResultSummary.textContent = text;
        this.divResultSummary.style.display = 'block';

        for (let i = 0; i < resultList.length; i++) {
            this.createSearchResultRow({
                parent,
                result: resultList[i].highlighted,
                path: resultList[i].rawData[ModDataTree.CRITERIA_LABEL.PATH.key],
            });
        }
    }

    expandPathToNode(input) {
        const pathParts = input.path.split('.');
        let currentDetails = this.divOuter.querySelector('.base_mod-data-tree_inner');

        for (const part of pathParts) {
            if (!currentDetails) break;

            // Find the <li> containing a <summary> with this key
            const summary = Array.from(currentDetails.querySelectorAll('summary'))
                .find(s => s.querySelector('.label')?.textContent === part);

            if (summary) {
                const details = summary.closest('details');
                if (details) details.open = true; // open this node
                currentDetails = details; // descend into this node for next iteration
            } else {
                break; // path not found
            }
        }

        // Scroll the last summary (target node) into view
        const targetSummary = currentDetails?.querySelector('summary');
        if (targetSummary) {
            targetSummary.scrollIntoView({ behavior: 'smooth', block: 'center' });
            this.highlightNodeTemporarily({ node: targetSummary, });
        }
    }

    highlightText(input) {
        const { text, matchingTermList } = input;
        // Escape regex special characters for each term
        const escapedTermList = matchingTermList.map(term => term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
        // Combine into a single regex pattern, match any term (OR)
        const regex = new RegExp(`(${escapedTermList.join('|')})`, 'gi');
        // Replace all matches with highlight span
        const highlightText = text.replace(regex, '<span class="base_mod-data-tree_highlight-search">$1</span>');
        return { highlightText, };
    }

    searchSummaryForTerm(input) {
        const { summary, searchTerm, searchCriteria, } = input;
        const terms = searchTerm.split(/\s+/);
        const highlighted = {};
        const rawData = {};
        for (let i = 0; i < ModDataTree.INFO_KEY_LIST.length; i++) {
            const key = ModDataTree.INFO_KEY_LIST[i].key;
            highlighted[key] = summary.dataset[key];
            rawData[key] = summary.dataset[key];
        }
        let hasMatch = false;
        for (const [key, text] of Object.entries(highlighted)) {
            if (!searchCriteria[key]) continue;

            const matchingTermList = terms.filter(term => text.toLowerCase().includes(term));
            if (matchingTermList.length > 0) {
                const { highlightText, } = this.highlightText({ text, matchingTermList, });
                highlighted[key] = highlightText;
                hasMatch = true;
            }
        }
        return { hasMatch, highlighted, rawData }; // no summary included
    }

    searchNodes(input) {
        let searchTerm = input.searchTerm.toLowerCase();

        const searchCriteria = {};
        for (let i = 0; i < ModDataTree.CRITERIA_SINGLE.length; i++) {
            const key = ModDataTree.CRITERIA_SINGLE[i].key;
            searchCriteria[key] = this.cbSearchCriteria[key].checked;
        }
        const resultList = [];
        const summaries = this.divOuter.querySelectorAll('.base_mod-data-tree_inner summary');
        summaries.forEach(summary => {
            const searchSummaryResult = this.searchSummaryForTerm({ summary, searchTerm, searchCriteria });
            if (searchSummaryResult.hasMatch) {
                resultList.push({
                    highlighted: searchSummaryResult.highlighted,
                    rawData: searchSummaryResult.rawData,
                });
            }
        });
        return { resultList, };
    }

    // Handle search input (works for text input or checkboxes)
    handleSearchInput(input) {
        const searchTerm = this.inputSearch.value.trim();
        if (!searchTerm || searchTerm.length < 3) return;

        this.divResultInner.innerHTML = '';
        const { resultList, } = this.searchNodes({ searchTerm });
        if (resultList.length === 0) {
            this.divResultSummary.textContent = taggedString.modDataTreeLabelNoResult(searchTerm);
            this.divResultSummary.style.display = 'block';
            return;
        }

        const { sortResultList, } = this.sortResultList({ resultList, });
        this.populateDivResult({
            parent: this.divResultInner,
            resultList: sortResultList,
            searchTerm,
        });
    }

    setupSearchListeners(input) {
        const debounce = (func, wait) => {
            let timeout;
            return (...args) => {
                clearTimeout(timeout);
                timeout = setTimeout(() => func.apply(this, args), wait);
            };
        };

        // Attach debounced handler to search input
        const debouncedHandler = debounce(this.handleSearchInput.bind(this), 300);
        this.inputSearch.addEventListener('input', debouncedHandler);

        // Attach to all search criteria checkboxes
        ModDataTree.CRITERIA_SINGLE.forEach(item => {
            const checkbox = this.cbSearchCriteria[item.key];
            if (checkbox) {
                checkbox.addEventListener('change', () => this.handleSearchInput());
            }

        });
        this.cbSearchCriteria[ModDataTree.CRITERIA_LABEL.ALL.key].addEventListener('change', () => this.handleSearchInput());

        this.selectSortCriteria.addEventListener('change', () => {
            this.handleSearchInput();
        });
        this.selectSortOrder.addEventListener('change', () => {
            this.handleSearchInput();
        });
    }

    onVisible(input) {
        this.inputSearch.focus();
    }

    sortResultList(input) {
        const { resultList, } = input;
        const defaultSortCriteriaId = ModDataTree.CRITERIA_LABEL.PATH.key;
        const criteria = this.selectSortCriteria?.value || defaultSortCriteriaId;
        const order = this.selectSortOrder?.value === ModDataTree.CRITERIA_LABEL.ORDER_DESC ? 'desc' : 'asc';
        const specialSortCriteriaId = ModDataTree.CRITERIA_LABEL.MOD_COUNT.key;
        const getFieldValue = (item, criteria) => {
            const key = criteria.replace(ModDataTree.CRITERIA_LABEL.SORT_CRITERIA_PREFIX, '');
            if (criteria == specialSortCriteriaId) {
                return parseInt(item[key]) || 0;
            }
            return (item[key] ? String(item[key]).toLowerCase() : '');
        };

        resultList.sort((a, b) => {
            const valA = getFieldValue(a.rawData, criteria);
            const valB = getFieldValue(b.rawData, criteria);

            if (valA < valB) return order === 'asc' ? -1 : 1;
            if (valA > valB) return order === 'asc' ? 1 : -1;
            return 0;
        });
        return { sortResultList: resultList, };
    }

    highlightNodeTemporarily(input) {
        const { node, duration = 2500 } = input;
        console.log(node);
        // Remove previous highlight if exists
        if (this.lastHighlightedNode) {
            this.lastHighlightedNode.classList.remove('temp-highlight');
        }
        if (this._highlightTimer) {
            clearTimeout(this._highlightTimer);
            this._highlightTimer = null;
        }

        node.classList.add('temp-highlight');
        this.lastHighlightedNode = node;

        this._highlightTimer = setTimeout(() => {
            node.classList.remove('temp-highlight');
            this._highlightTimer = null;
            this.lastHighlightedNode = null;
        }, duration);
    }
}

/*


1. Search & Filter

Add a search bar to filter nodes by key, creator, or modifier.

Highlight matching nodes and collapse non-matching branches.

Optionally, allow regex search for advanced filtering.

3. Sorting Options

Sort child nodes alphabetically or by creator/modifier.

Option to group nodes by creator, last modifier, or type of data.


7. Color Coding & Styling

Differentiate leaf nodes vs. parent nodes more clearly (e.g., subtle background colors).

Highlight nodes modified by specific mods using a configurable color scheme.

Option to theme the tree (light/dark or custom).

8. Node Actions

Context menu on right-click for:

Show only this branch

Filter by creator/modifier

9. Performance Features

Lazy loading for large mod trees to avoid rendering everything at once.

Virtualized scrolling for huge datasets.

Option to collapse branches by default to reduce clutter.

10. Export / Import

Export the mod history snapshot as JSON for debugging.

Option to import a mod history snapshot to test offline or compare.

*/