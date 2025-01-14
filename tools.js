// Simple Navigation Tools
// wheatleymf, July 2024
//
// This isn't meant to be a nice, clean code that is easy to pick up - I just wrote a quick tool for myself
// because I CBA setting up a proper content system on my website. Yes, this is ugly, I'm sorry.
// If someone can implement all of this properly in a clean and convenient way, I'll be glad to help.

let currentCategory;
let loaderTarget = document.querySelector( ".loader" );

const Header = document.title;
const QuickNavigation = document.querySelector( ".headers" );

function GetCaller( name )
{
    return document.querySelector('[category=' + name + ']');
}

function UpdateLoader( status, callerObject = undefined )
{
    switch( status )
    {
        case true:
            loaderTarget.classList.remove("hidden");
            callerObject?.classList.add("pending");
            break;
        case false:
            loaderTarget.classList.add("hidden");
            callerObject?.classList.remove("pending");
            break;
    }
}

function UpdateSidebar( categoryName )
{
    if ( currentCategory != null )
        currentCategory.classList.remove( "currentCategory" );

    let callerObject = GetCaller( categoryName );

    if ( callerObject == undefined || callerObject == null )
    {
        console.warn( "Couldn't find the requested sidebar button. Is it missing?.." );
        return;
    }

    currentCategory = callerObject;
    UpdateLoader( false, callerObject );
    callerObject.classList.add( "currentCategory" );
}

function DisplayImage( image )
{
    let url = image.getAttribute("src");

    const div = document.createElement( "div" );
    const fullimg = document.createElement( "img" );
    const link = document.createElement( "a" );
    const tip = document.createElement( "p" );
    
    fullimg.setAttribute( "src", url );
    div.appendChild( fullimg );
    div.id = "imageviewer";

    link.setAttribute( "href", window.location.origin + url );
    link.setAttribute( "target", "_blank" );
    link.innerHTML = "View in separate tab";
    div.appendChild( link );

    tip.innerHTML = "Click on the image to close this thing";
    div.appendChild( tip );

    fullimg.onclick = function() { div.remove(); };

    document.body.append( div );
}

function LoaderError( reason, category, target, code )
{
    UpdateLoader( false, category );

    target.innerHTML = `<h1>Oops...</h1> ${reason}</p> <p>Couldn't retrieve entry <b>${category.getAttribute("category")}</b>.</p>`;
    document.title = `Error ${code} :-(`;

    const details = ( function() {
        switch (code)
        {
            case 404:
                return "<b>This blogpost is not found</b>. If you are really sure it's meant to be here, on this exact URL, please let me know. :S";
            case 403:
                return "<b>No access</b>. What the fuck?";
            case 400:
                return "<b>Bad request!</b> Someone screwed up... Either you, or me.";
            case 401:
                return "<b>Unauthorized</b>. This isn't right, please let me know.";
            case 502:
                return "<b>Bad Gateway</b>. How :|";
            case 503:
                return "<b>Service Unavailable</b>. Well shit, server isn't doing well right now. Please be nice and don't spam reload button, just try again in 15 minutes.";
        }
    } )();

    target.innerHTML += details;
}

function ParseDOM( contents ) 
{
    let parser = new DOMParser();
    let doc = parser.parseFromString( contents, "text/html" );

    return doc;
}

function UpdateTitle( loadedPage )
{
    let parsedData = ParseDOM( loadedPage );
    let PageName = parsedData.querySelector( ".description h1" ).textContent;

    return `${ PageName } :: ${ Header }`;
}

function ResetScroll()
{
    window.scrollTo( {
        top: 0,
        behavior: 'smooth'
    } );
}

let CurrentHeading; 

function UpdateNavigator( page )
{
    // Reset the contents of a quick navigation
    QuickNavigation.innerHTML = '';

    let headings = page.querySelectorAll( 'h2,h3' );
    
    headings.forEach( element => {
        // Populate the navigator with all found headings and subheadings
        let subheader = document.createElement( 'span' );
        subheader.className = element.tagName == "H2" ? "header" : "subheader";
        subheader.dataset.targetId = subheader.id;
        subheader.innerHTML = element.textContent;

        // Hook up an event that moves reader to selected heading 
        subheader.onclick = function() {
            window.scrollTo( {
                top: element.getBoundingClientRect().top + window.scrollY - 50,
                behavior: 'smooth'
            });
        }

        QuickNavigation.appendChild( subheader );
    });

    let navItems = document.querySelectorAll(".headers span");

    // Implement intersection observer so we can nicely keep track of which section user is currently reading.
    // There are a few issues when user scrolls between two sections or when more than 1 target is in viewport, 
    // but overall this is better than nothing. 
    const observer = new IntersectionObserver( 
        (entries) => {

            entries.forEach( (entry) => {
                const navItem = [...navItems].find( 
                    (item) => item.textContent == entry.target.innerHTML
                );

                if (entry.isIntersecting) {
                    navItem?.classList.add( 'current' );
                    CurrentHeading?.classList.remove( 'current' );

                    CurrentHeading = navItem;
                }
            });
        }, 
        {
            root: null,
            threshold: 0.5
        }
    );

    // Hook up observer to all new created headings 
    headings.forEach( (heading) => observer.observe( heading ) );
}

async function DisplayCategory( categoryName )
{
    let target = document.querySelector(".contents");
    let callerObject = GetCaller( categoryName );

    let newPage;
    let lastModified;
    let status = true;
    let responseCode;

    UpdateLoader( true, callerObject );

    // We do double fetch here mostly for two reasons,
    // 1) requesting with HEAD method reduces amount of data we receive in a response,
    // 2) I don't have much time to implement this in a cleaner way

    await fetch( 'categories/' + categoryName + '.html', { method: 'HEAD' } )
        .then( function( response ) {
            responseCode = response.status;

            if ( !response.ok ) {
                status = response.ok;
                throw new Error( "Fetching error, server replied with code " + response.status );
            } else {
                lastModified = new Date( response.headers.get('Last-Modified') );
            }
        }).catch( function(err) {
            LoaderError( err, callerObject, target, responseCode );
        })

    if ( !status ) return;

    await fetch( 'categories/' + categoryName + '.html' )
        .then( response => response.text() )
        .then( text => newPage = text);

    // Update target area of the main page with downloaded contents
    target != undefined ? target.innerHTML = newPage : console.error("Missing target element for new content!");
    target.innerHTML += `<div class='meta'>last article update: ${lastModified.toLocaleString()}</div>`;
    
    // Update the title page.. this is a very hacky way because it's basically an afterthought, this should be much better. 
    document.title = UpdateTitle( newPage );

    // Set the page scroll at the top after opening a new page.
    ResetScroll();

    // Update quick navigation window depending on what given article contains
    UpdateNavigator( target );

    // Make sure to run code highlighter on recevied page before rendering it
    hljs.highlightAll( );

    // Add "onclick" event on all images featured in the downloaded article
    let images = document.getElementsByTagName("img");
    let imgList = Array.prototype.slice.call(images);
    imgList.forEach( (element) => element.onclick = function() { DisplayImage( element ); } );

    // Update the URL we're seeing in the search bar, so it can be shared with others and won't reset currently open article on page reload
    window.history.pushState( null, "title", `?entry=${categoryName}` );
    UpdateSidebar( categoryName );
} 

function ReadQuery()
{
    const params = new Proxy( new URLSearchParams( window.location.search ), {
        get: (searchParams, prop) => searchParams.get(prop),
    });

    let value = params["entry"];

    if ( value != null )
    {
        DisplayCategory( value );
        return true;
    } else { return false }
}

// Redirect user to requested article entry if address bar has it, if it's null then force open "welcome".
let RequiresEntry = ReadQuery();

if ( !RequiresEntry )
    DisplayCategory( "welcome" );

