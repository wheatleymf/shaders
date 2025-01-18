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

class ArticleHeader extends HTMLElement {
    constructor() {
        super();

        const name = this.getAttribute("name");
        const icon = this.getAttribute("icon");
        const category = this.getAttribute("category");

        let wrapper = document.createElement("div");
        wrapper.classList.add("ArticleHeader");

        let icondiv = document.createElement("div");
        icondiv.classList.add("icon");
        let iconspan = document.createElement("span");
        iconspan.classList.add("material-symbols-sharp");

        let datadiv = document.createElement("div")
        datadiv.classList.add("description");
        let cat = document.createElement("span");
        let header = document.createElement("h1");

        iconspan.textContent = icon;
        cat.textContent = category;
        header.textContent = name;

        datadiv.appendChild( cat );
        datadiv.appendChild( header );
        icondiv.appendChild( iconspan );
        wrapper.appendChild( icondiv );
        wrapper.appendChild( datadiv );

        this.appendChild( wrapper );
    }
}

class ArticleRef extends HTMLElement {
    constructor()
    {
        super();

        const link = this.getAttribute( "link" );
        this.classList.add("ref");

        this.onclick = function() {
            DisplayCategory( link );
        }
    }
}

customElements.define("download-file", DownloadElement);
customElements.define("article-header", ArticleHeader);
customElements.define("article-ref", ArticleRef );