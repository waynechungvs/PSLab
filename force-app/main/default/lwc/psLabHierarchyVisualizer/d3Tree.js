/**
 * @description A service class to encapsulate all D3.js tree visualization logic.
 * It handles the creation, rendering, and interaction with the SVG chart.
 */
export class D3Tree {

    _container;
    _svg;
    _rootNode;
    _treeLayout;
    _linkGenerator;
    _nodeGroup;
    _linkGroup;


    _margin = { top: 10, right: 10, bottom: 10, left: 10 };
    _nodeDx = 25;
    _nodeDy;
    _highlightedIds = new Set();

    constructor(container) {
        this._container = container;
    }

    initialize(data) {
        const containerWidth = this._container.clientWidth || 928;
        this._nodeDy = (containerWidth - this._margin.right - this._margin.left) / 6;

        this._treeLayout = d3.tree().nodeSize([this._nodeDx, this._nodeDy]);
        this._linkGenerator = d3.linkHorizontal().x(d => d.y).y(d => d.x);

        this._svg = d3.select(this._container).append("svg")
            .attr("width", containerWidth)
            .attr("style", "overflow: visible; width: 100%; max-width: 100%; height: auto; font: 10px sans-serif; user-select: none;");

        const initialLeftMargin = 120;

        this._linkGroup = this._svg.append("g")
            .attr("fill", "none")
            .attr("stroke", "#7592e7")
            .attr("stroke-opacity", 0.4)
            .attr("stroke-width", 1.5)
            .attr("transform", `translate(${initialLeftMargin},${this._margin.top})`);

        this._nodeGroup = this._svg.append("g")
            .attr("cursor", "pointer")
            .attr("pointer-events", "all")
            .attr("transform", `translate(${initialLeftMargin},${this._margin.top})`);

        this.update(data);
    }

    update(data, highlightedIds = new Set()) {
        if (!data) return;
        this._highlightedIds = highlightedIds;
        this._rootNode = d3.hierarchy(data, d => d.children);
        this._rootNode.x0 = this._nodeDy / 2;
        this._rootNode.y0 = 0;

        // Collapse all nodes except the root's direct children initially
        this._rootNode.descendants().forEach((d, i) => {
            d.id = d.data.id || `${d.data.name}-${d.depth}-${i}`;
            d._children = d.children;
            if (d.depth > 0) d.children = null;
        });

        this._render(this._rootNode);
    }

    expandAll() {
        if (!this._rootNode) return;
        this._rootNode.each(d => {
            if (d._children) {
                d.children = d._children;
                d._children = null;
            }
        });
        this._render(this._rootNode);
    }

    collapseAll() {
        if (!this._rootNode) return;
        this._rootNode.each(d => {
            if (d.depth > 0 && d.children) {
                d._children = d.children;
                d.children = null;
            }
        });
        this._render(this._rootNode);
    }


    _render(source) {
        if (!this._rootNode || !this._svg || !this._nodeGroup || !this._linkGroup) {
            return;
        }

        const duration = 250;
        const nodes = this._rootNode.descendants().reverse();
        const links = this._rootNode.links();

        this._treeLayout(this._rootNode);

        let top = this._rootNode;
        let bottom = this._rootNode;
        this._rootNode.eachBefore(node => {
            if (node.x < top.x) top = node;
            if (node.x > bottom.x) bottom = node;
        });
        const height = bottom.x - top.x + this._margin.top + this._margin.bottom;
        const containerWidth = this._container.clientWidth || 928;

        const transition = this._svg.transition()
            .duration(duration)
            .attr("height", height)
            .attr("viewBox", [0, top.x - this._margin.top, containerWidth, height]);

        const node = this._nodeGroup.selectAll("g").data(nodes, d => d.id);

        const nodeEnter = node.enter().append("g")
            .attr("transform", `translate(${source.y0},${source.x0})`)
            .attr("fill-opacity", 0)
            .attr("stroke-opacity", 0)
            .on("click", (event, d) => {
                if (d.children) {
                    d._children = d.children;
                    d.children = null;
                } else {
                    d.children = d._children;
                    d._children = null;
                }
                this._render(d);
            });

        const tooltipDiv = d3.select(this._container).select('.d3-tooltip');
        nodeEnter
            .on("mouseover", (event, d) => {
                const data = d.data || {};
                if (data.type === "PSG" || data.type === "PS" || data.type === "parentNode") return;

                const contentHtml = `
                    <div class="tooltip-line"><strong>Name:</strong> ${data.label || data.name || "N/A"}</div>
                    <div class="tooltip-line"><strong>API Name:</strong> ${data.name || "N/A"}</div>
                    ${data.description ? `<div class="tooltip-line"><strong>Description:</strong> ${data.description}</div>` : ""}
                    ${data.status ? `<div class="tooltip-line"><strong>Status:</strong> ${data.status}</div>` : ""}
                    ${data.createdBy ? `<div class="tooltip-line"><strong>Created By:</strong> ${data.createdBy}</div>` : ""}
                    ${data.lastModifiedBy ? `<div class="tooltip-line"><strong>Modified By:</strong> ${data.lastModifiedBy}</div>` : ""}
                    ${data.lastModifiedDate ? `<div class="tooltip-line"><strong>Modified Date:</strong> ${new Date(data.lastModifiedDate).toLocaleString()}</div>` : ""}
                `;

                const tooltipHeight = tooltipDiv.node().offsetHeight;
                const containerHeight = this._container.clientHeight;
                const [mouseX, mouseY] = d3.pointer(event, this._container);
                const scrollLeft = this._container.scrollLeft;
                const scrollTop = this._container.scrollTop;
                let finalY;
                const verticalOffset = 20;
                if (mouseY + tooltipHeight + verticalOffset > containerHeight) {
                    finalY = mouseY + scrollTop - tooltipHeight - (verticalOffset / 2);
                } else {
                    finalY = mouseY + scrollTop + verticalOffset;
                }
                const finalX = mouseX + scrollLeft + 15;

                tooltipDiv.html(contentHtml)
                    .style("left", finalX + "px")
                    .style("top", finalY + "px")
                    .style("visibility", "visible")
                    .style("background", "rgba(255, 255, 255, 0.95)")
                    .style("border", "1px solid #ccc")
                    .style("padding", "8px")
                    .style("border-radius", "4px")
            })
            .on("mouseout", () => {
                tooltipDiv.style("visibility", "hidden");
            });

        nodeEnter.append("circle")
            .attr("r", 3.0)
            .attr("fill", d => d._children ? "#29f60d" : "#999");

        const wrapWidth = this._nodeDy ? Math.max(50, this._nodeDy * 0.9) : 90;
        nodeEnter.append("text")
            .attr("dy", "0.31em")
            .attr("x", d => d._children ? -8 : 8)
            .attr("text-anchor", d => d._children ? "end" : "start")
            .text(d => d.data.label ? `${d.data.label} (${d.data.name})` : d.data.name)
            .attr("paint-order", "stroke")
            .attr("stroke", "white")
            .attr("stroke-width", 3)
            .call(this._wrapText, wrapWidth);

        const nodeUpdate = node.merge(nodeEnter).transition(transition)
            .attr("transform", d => `translate(${d.y},${d.x})`)
            .attr("fill-opacity", 1)
            .attr("stroke-opacity", 1);

        nodeUpdate.select("circle")
            .attr("r", d => this._highlightedIds.has(d.data.id) ? 4.5 : 3.0)
            .attr("fill", d => d._children ? "#29f60d" : "#999")
            .attr("stroke", d => this._highlightedIds.has(d.data.id) ? "#606c38" : "none")
            .attr("stroke-width", d => this._highlightedIds.has(d.data.id) ? 2 : 0);

        node.exit().transition(transition).remove()
            .attr("transform", `translate(${source.y},${source.x})`)
            .attr("fill-opacity", 0)
            .attr("stroke-opacity", 0);

        const link = this._linkGroup.selectAll("path").data(links, d => d.target.id);

        const linkEnter = link.enter().append("path")
            .attr("d", d => {
                const o = { x: source.x0, y: source.y0 };
                return this._linkGenerator({ source: o, target: o });
            });

        link.merge(linkEnter).transition(transition)
            .attr("d", this._linkGenerator);

        link.exit().transition(transition).remove()
            .attr("d", d => {
                const o = { x: source.x, y: source.y };
                return this._linkGenerator({ source: o, target: o });
            });

        this._rootNode.eachBefore(d => {
            d.x0 = d.x;
            d.y0 = d.y;
        });
    }


    _wrapText(textSelection, width) {
        textSelection.each(function() {
            const text = d3.select(this);
            const words = text.text().split(/\s+/).reverse();
            let word;
            let line = [];
            const lineHeight = 1.1; // ems
            const x = text.attr("x");
            const dy = parseFloat(text.attr("dy"));
            text.text(null);

            let tspan = text.append("tspan").attr("x", x).attr("dy", dy + "em");

            while (word = words.pop()) {
                line.push(word);
                tspan.text(line.join(" "));
                if (tspan.node().getComputedTextLength() > width && line.length > 1) {
                    line.pop();
                    tspan.text(line.join(" "));
                    line = [word];
                    tspan = text.append("tspan").attr("x", x).attr("dy", lineHeight + "em").text(word);
                }
            }
        });
    }

    hideTooltip() {
        if (this._container) {
            d3.select(this._container).select('.d3-tooltip').style('visibility', 'hidden');
        }
    }
}