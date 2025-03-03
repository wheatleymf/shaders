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

        // Icon section
        const icondiv = document.createElement("div");
        icondiv.classList.add("icon");
        const iconSpan = document.createElement("span");
        iconSpan.classList.add("material-symbols-sharp");
        iconSpan.classList.add("notranslate");
        iconSpan.textContent = icon;
        icondiv.appendChild(iconSpan);

        // File & title section
        const file = document.createElement("div");
        file.classList.add("file");
        const fileTitle = document.createElement("span");
        fileTitle.textContent = title;
        file.appendChild(fileTitle);
        const fileName = document.createElement("b");
        fileName.textContent = GetFilenameFromURL(link);
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
        iconspan.classList.add("notranslate");

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

class NavigationItem extends HTMLElement {
    constructor()
    {
        super();

        let internalName = this.getAttribute( "link" );
        let icon = this.getAttribute( "icon" );

        let a = document.createElement( "a" );
        let span = document.createElement( "span" );
        span.classList.add( "material-symbols-sharp" );
        span.classList.add( "notranslate" );
        span.textContent = icon;

        let displayname = document.createElement( "k" ); // this isn't real lol
        displayname.textContent = this.textContent;

        this.innerHTML = '';
        this.appendChild( span );
        this.appendChild( displayname );

        this.setAttribute( "category", internalName );
        this.onclick = function() {
            DisplayCategory( internalName );
        }

    }
}

class Contributor extends HTMLElement
{
    constructor()
    {
        super();

        let name = this.getAttribute( "name" );
        let url = this.getAttribute( "url" );       // URL as any link to user's website, or GitHub link
        let icon = this.getAttribute( "icon" );     // Expected to be URL too 

        let div = document.createElement( "div" );
        let img = document.createElement( "img" );
        let text = document.createElement( "div" );

        img.setAttribute( "src", icon );
        text.textContent = name;
        text.classList.add( "name" );
        div.classList.add( "contributor" );

        div.appendChild( img );
        div.appendChild( text );
        
        this.appendChild( div );
        this.onclick = function() {
            window.open( url, "_blank" );
        }
    }
}

customElements.define( "download-file", DownloadElement );
customElements.define( "article-header", ArticleHeader );
customElements.define( "article-ref", ArticleRef );
customElements.define( "nav-item", NavigationItem );
customElements.define( "contributor-tag", Contributor );