class DownloadElement extends HTMLElement {
    constructor() {
        super();

        const link = this.getAttribute("url");
        const title = this.getAttribute("title");
        const icon = this.getAttribute("icon");

        const anchor = document.createElement("a");
        anchor.setAttribute("part", "dl");
        anchor.classList.add("dl");
        anchor.href = link;
        anchor.target = "_blank";

        // Container
        const container = document.createElement("div");
        container.classList.add("download");
        container.setAttribute("part", "download");

        // Icon section
        const icondiv = document.createElement("div");
        icondiv.classList.add("icon");
        icondiv.setAttribute("part", "icon");
        const iconSpan = document.createElement("span");
        iconSpan.classList.add("material-symbols-sharp");
        iconSpan.textContent = icon;
        iconSpan.setAttribute("part", "iconstring");
        icondiv.appendChild(iconSpan);

        // File & title section
        const file = document.createElement("div");
        file.classList.add("file");
        file.setAttribute("part", "file");
        const fileTitle = document.createElement("span");
        fileTitle.textContent = title;
        fileTitle.setAttribute("part", "fileTitle");
        file.appendChild(fileTitle);
        const fileName = document.createElement("b");
        fileName.textContent = GetFilenameFromURL(link);
        fileName.setAttribute("part", "fileName");
        file.appendChild(fileName);

        // Add icon/file blocks into main wrapper div
        container.appendChild(icondiv);
        container.appendChild(file);

        // Then add it into <A>
        anchor.appendChild(container);

        // Return 
        this.appendChild(anchor);
    }
}

customElements.define("download-file", DownloadElement);