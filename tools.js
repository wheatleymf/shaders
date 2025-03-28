// Simple Navigation Tools
// wheatleymf, July 2024 - January 2025
//
// This is very bad. I could've done a better job. This could've been done better using frameworks. 
// I *could* do it better, but implementing actual content was more important to me... 
// I am not trying to justify this mess! When you're limited on time, sometimes you should do things
// like a moron. I can always come back to this later and fix all issues, step by step. 

let currentCategory;
let loaderTarget = document.querySelector( ".loader" );

const Header = document.title;
const QuickNavigation = document.querySelector( ".headers" );

function HandleStart() {
    window.addEventListener( "load", function() {
        console.log( "done :-)" );
    
        let loadingBoilerplate = document.querySelector( ".placeholder" );
    
        loadingBoilerplate.addEventListener( "animationend", function() {
            loadingBoilerplate.remove();
        });
        loadingBoilerplate.classList.add( "removing" );
    });
    
    setTimeout( () => {
        let loading = document.querySelector( ".placeholder" );
        
        let notification = document.createElement( "span" );
        notification.textContent = "looks like page isn't booting up :( please see console and try reloading.";
    
        loading?.appendChild( notification );
    
    }, 20000 );
}

//
// Transforms the relative link into proper URL, then grabs the last part that displays 
// the file name and extension. Used for special <download-file> tag.  
// 
function GetFilenameFromURL( url )
{
    const baseDomainURL = window.location.protocol + "//" + window.location.hostname;
    url = baseDomainURL + url;

    try {
        let parsedURL = new URL( url );
        return parsedURL.pathname.split( '/' ).pop();
    } catch ( error )
    {
        console.error("[DOWNLOAD TAG] Couldn't parse the URL: ", error, url); 
        return null;
    }
}

// 
// This is also 6 months old and I don't remember what the fuck is it doing. 
// 
function GetCaller( name )
{
    return document.querySelector('[category=' + name + ']');
}

//
// This is bad
// 
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

//
// Little helper to switch between night and light themes
//
let Theme = {
    _UpdateState: function( themename ) {
        document.documentElement.classList.toggle( themename );
        document.body.classList.toggle( themename );
    },
    Toggle: function() {
        let doc = document.documentElement;

        this._UpdateState( "night" );
    
        localStorage.setItem( "nighttheme", doc.classList.contains( "night" ) );
    },
    Restore: function() {
        let val = localStorage.getItem( "nighttheme" );

        // Wow this is bad
        // In my defense, looks like local storage writes shit as strings, 
        // i'll see if I can make values be treated as proper types
        if (val == "true")
            this.Toggle();
    }
}

// 
// Little navigation visibility handler
//
let Navigation = {
    Show: function( isCodeblock ) {
        // Do nothing if user is swiping around the code snippet area
        if ( isCodeblock )
            return;
        
        document.querySelector(".navigation").classList.add( "displaying" );
        document.querySelector(".switch").style.opacity = 1;
        document.body.style.overflowY = 'hidden';   // Hacky; block scrolling for body element while navigation is open 
    },
    Hide: function() {
        document.querySelector(".navigation").classList.remove( "displaying" );
        document.querySelector(".switch").style.opacity = 0;
        document.body.style.overflowY = 'visible'; 
    }
}

//
// Enables mobile-style functionality for the navigation bar on the left.
// If user swipes to the right, this menu will open. Swiping to the left will close it. 
//
function EnableNavigationSlide()
{
    document.addEventListener("DOMContentLoaded", function () {
        let touchStartX = 0;
        let touchCurrentX = 0;
        const swipeThreshold = 75;

        let isCodeblock = false;
    
        document.addEventListener("touchstart", function (e) {
            touchStartX = e.touches[0].clientX;
            
            // Make sure navigation isn't showing up when user is touching code block or any child elements
            // This will return either 'true' or 'null', which is probably not good, but it works
            isCodeblock = e.target.tagName == "CODE" || e.target.closest("CODE"); 
        });
    
        document.addEventListener("touchmove", function (e) {
            touchCurrentX = e.touches[0].clientX;
        });
    
        // Call .Hide or .Show functions if swipe value meets the threshold criteria in given direction 
        document.addEventListener("touchend", function () {
            if (touchCurrentX < touchStartX - swipeThreshold) {
                Navigation.Hide();
            } else if (touchCurrentX > touchStartX + swipeThreshold) {
                Navigation.Show( isCodeblock );
            }
        });
    });
}

//
// Check if user's viewport matches general mobile width, this will be used to 
// update page layout to be more comfortable for reading from phones. 
// 
function isMobile() {
    return window.outerWidth <= 768;
}

// 
// This enables bunch of handlers and adjusts CSS styling to be more comfortable for the reader. 
// Triggers only once during the initial loading of page.
// Not sure if this will work the way I imagine it lol, sorry!
//
function EnableMobileMode( isMobile )
{
    if (!isMobile) return; 

    let navigation = document.querySelector( ".navigation" );
    navigation.classList.add( "mobile" );
    let contents = document.querySelector( ".contents" );
    document.body.classList.add( "mobile" );

    EnableNavigationSlide();

    contents.classList.add( "mobile" );    
}

// 
// Update classes for the elements in sidebar navigation to indicate
// which page is currently being read
// This is stupid. And bad. But this is a ~6 months old bit.  
//
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

// 
// Creates a new DOM element with the image preview in higher res.
// Adds a button that prompts to view the image in a separate tab. 
//
function DisplayImage( image )
{
    let url = image.getAttribute("src");

    const div = document.createElement( "div" );
    const fullimg = document.createElement( "img" );
    const link = document.createElement( "a" );
    const tip = document.createElement( "p" );

    // Little override to throw user into a new tab with the full image instead of creating a new element
    if ( isMobile() )
    {
        const imageTab = window.open( window.location.origin + url, "_blank" );
        imageTab.focus();
        return;
    }

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

//
// Very rough implementation of error handler in case something on the page breaks 
// horribly bad.
//
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

// 
// Automatically parses downloaded HTML content into a proper DOM elements
// which allows doing querySelector and any other DOM element manipulations. 
// 
function ParseDOM( contents ) 
{
    let parser = new DOMParser();
    let doc = parser.parseFromString( contents, "text/html" );

    return doc;
}

//
// Updates the page title 
// 
function UpdateTitle( loadedPage )
{
    let parsedData = ParseDOM( loadedPage );
    let PageName = parsedData.querySelector( "article-header" )?.getAttribute("name");

    if ( PageName == undefined)
        console.warn("Couldn't read the article name! Please make sure that article is using <article-header> tag.");
    
    return `${ PageName } :: ${ Header }`;
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

//
// Returns the value for given query request.
// 
function GrabURLentry( name )
{
    const params = new Proxy( new URLSearchParams( window.location.search ), {
        get: (searchParams, prop) => searchParams.get(prop),
    });
    let value = params[ name ];

    return value; 
}

function TryRestoreScrolling( entry ) 
{
    // Reset scroll to 0 if there's no value saved
    if ( !localStorage.getItem( entry ) )
    {
        window.scrollTo( {
            top: 0, 
            behavior: 'smooth'
        });
        
        return;
    }

    let position = localStorage.getItem( entry );

    window.scrollTo( {
        top: position,
        behavior: 'smooth'
    });
}

function SaveScrollPosition()
{
    let page = GrabURLentry( "entry" );
    localStorage.setItem( page, window.scrollY );
}

async function DisplayCategory( categoryName )
{
    let target = document.querySelector(".contents");
    let callerObject = GetCaller( categoryName );

    let newPage;
    let lastModified;
    let status = true;
    let responseCode;

    // Write the scroll position for the current page
    SaveScrollPosition();

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
    let meta = `<div class='meta'>last website update: ${lastModified.toLocaleString()}</div>`;
    target != undefined ? target.innerHTML = newPage + meta : console.error("Missing target element for new content!");
    
    // Update the title page.. this is a very hacky way because it's basically an afterthought, this should be much better. 
    document.title = UpdateTitle( newPage );

    // Try restoring the scroll for this page if it's been locally saved
    // If there's no scroll position saved on this page, scroll to top. 
    TryRestoreScrolling( categoryName );

    // Update quick navigation window depending on what given article contains
    UpdateNavigator( target );

    // Make sure to run code highlighter on recevied page before rendering it
    hljs.highlightAll( );

    // If we are in mobile mode, hide navigation menu after loading new page
    if( isMobile() )
    {
        Navigation.Hide();
    }

    // Add "onclick" event on all images featured in the downloaded article
    let images = document.getElementsByTagName("img");
    let imgList = Array.prototype.slice.call(images);
    imgList.forEach( (element) => element.onclick = function() { DisplayImage( element ); } );

    // Update the URL we're seeing in the search bar, so it can be shared with others and won't reset currently open article on page reload
    window.history.pushState( null, "title", `?entry=${categoryName}` );
    UpdateSidebar( categoryName );
} 

// 
// Monitor user search state: if they move back/forward in page history, it should display the correct article. 
//
let alreadyMonitoring = false;
function MonitorQueryUpdates()
{
    if (alreadyMonitoring)
        return new Error( "Attempting to start monitor query updates when it is already initialized!" );

    window.addEventListener( 'popstate', () => {
        const params = new URLSearchParams( window.location.search );
        const entry = params.get( "entry" ); 

        DisplayCategory( entry );
    });

    alreadyMonitoring = true;
}

function ReadQuery()
{
    let value = GrabURLentry( "entry" );

    if ( value != null )
    {
        DisplayCategory( value );
        return true;
    } else { return false }
}

/*

    This is the start of actual functionality, it starts with hooking up a "load" event listener 
    and timer. Load listener will automatically hide the loader <div> element once page fully loads.
    However, if something goes wrong and loader stays visible for more than 20 seconds, timer will attempt
    to display a warning about a potential problem. 
    
    Then, system processes the URL query to see if user is trying to request any specific page. 
    If that's the case, we're instantly calling DisplayCategory() to call the requested page. 
    If not, system will load up "welcome" page by default. 

    Then, website checks the local storage to see if user has night theme saved. Load it up if that's true.

    MonitorQueryUpdates() hooks up event listener that will check for any updates to the URL. This allows 
    user to use back/forward buttons in their browser to cycle between pages in their browsing history. 
    When URL state triggers, it will call DisplayCategory() with the corresponding value from query.
    
    EnableMobileMode() will enable special functionality to some of the static DOM elements like body 
    and navigation <div>, as long as passed boolean returns 'true'. 

*/

// Starting point 
HandleStart();

// Redirect user to requested article entry if address bar has it, if it's null then force open "welcome".
let RequiresEntry = ReadQuery();

if ( !RequiresEntry )
    DisplayCategory( "welcome" );

Theme.Restore();
MonitorQueryUpdates();
EnableMobileMode( isMobile() );
