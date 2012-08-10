var suggestioncount = -1;
var ajaxRequest = "";
var ajaxRequestSend = 0;
function select_suggestion(e) {
    var strSuggestiontext = e.textContent.trim();
    $('search_term').value = strSuggestiontext;
    $('suggestions').remove();
    //$('show_suggestion').writeAttribute('name','no_suggestion');
    suggestioncount = -1;
}

function highlightlabel(e) {
    $$('.highlightoption')[0].removeClassName('highlightoption');
    e.addClassName('highlightoption');
}

function searchsuggestions(e, oElement) {
    if(e.keyCode == 13 || e.keyCode == 40 || e.keyCode == 38) {
        // if(e.keyCode == 13)
        return false;
    }
    ajaxRequest = new Ajax.Request('get_search_suggestions', {
        parameters : {
            search_term : oElement.value
        },
        method : 'get'
    });
    ajaxRequestSend = 1;
}

function showsuggestion(event, oelem) {
    // $('show_suggestion').writeAttribute('name','show_suggestion');
    var osuggestions = $$('.suggestion');
    var ohoverelements = $$('.suggestionhover');
    $('search_suggestions').show();
    if(osuggestions.length === 0) {
        if(event.keyCode == 13) {
            submitsuggestion();
        }
        return;
    }
    if(ohoverelements.length > 0) {
        ohoverelements[0].removeClassName('suggestionhover');
    }
    switch (event.keyCode) {
        case 40:
            suggestioncount++;
            if(suggestioncount >= osuggestions.length) {
                suggestioncount = 0;
            }
            osuggestions[suggestioncount].addClassName('suggestionhover');
            break;

        case 38:
            suggestioncount--;
            if(suggestioncount <= -1) {
                suggestioncount = osuggestions.length - 1;
            }
            osuggestions[suggestioncount].addClassName('suggestionhover');
            break;

        case 13:
            if(suggestioncount != -1) {
                select_suggestion(osuggestions[suggestioncount]);
                suggestioncount = -1;
            }

            submitsuggestion();
            break;

        default:
            suggestioncount = -1;
    }
}

function showHideProbes(activity) {
    var bVisible = false;
    $$('.probes_container,.probes_header').each(function(oButtonContainer) {
        oButtonContainer.toggle();
        bVisible = bVisible || oButtonContainer.getStyle('display') == 'none';
    });
}

function showHideFilters(oLink) {
    var bVisible = false;
    $$('.collapse_filters').each(function(oButtonContainer) {
        oButtonContainer.toggle();
        bVisible = bVisible || oButtonContainer.getStyle('display') == 'none';
    });

    var strLinkText = "";
    var strExpandCollapseText = "";
    if(bVisible) {
        strLinkText = "Show Filters";
        strExpandCollapseText = "+";
    } else {
        strLinkText = "Hide Filters";
        strExpandCollapseText = "-";
    }

    $('oExpandCollapseText').update(strExpandCollapseText);
    oLink.update(strLinkText);
}

function uncheckedallprobes() {
    $$(".probe_items").each(function(e) {
        e.checked = false;
    });
}

function removesuggestions() {
    $('suggestions').remove();
}

function preventsubmit() {
    $('prevent_submit').setValue(1);
}

function allowsubmit() {
    $('prevent_submit').setValue(0);
}

function submitsuggestion() {
    $('prevent_submit').setValue(0);
    document.getElementsByName('GO')[0].click();
}

function CheckSubmitStatus() {
    var oVal = $('prevent_submit');
    if(oVal.value == 1) {
        oVal.setValue(0);
        return false;
    } else {
        return true;
    }
}

function abortAjaxRequest() {
    if(ajaxRequestSend) {
        ajaxRequest.transport.abort();
        ajaxRequestSend = 0;
        $('search_suggestions').hide();
        if($('suggestions')) {
            $('suggestions').remove();
        }

    }
}