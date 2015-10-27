package EnsEMBL::Web::Document::Element::SearchBox;

### Generates small search box (used in top left corner of pages)

use strict;

sub content {
    my $self = shift;
    my $species_defs = $self->species_defs;
    my $search_url = $species_defs->ENSEMBL_WEB_ROOT . "Multi/psychic";
    
    my $js = q\
       <script>
        window.onload = function() {
          (function (VectorBaseSearch, $, undefined) {

            if (VectorBaseSearch.data == undefined) {
              VectorBaseSearch.data = {};
            }

            VectorBaseSearch.init_autocomplete = function() {
              $("#block-search-form :text, #search-form :text").autocomplete({
                source: function (request, response) {
                  var field_id = this.element.attr('id');
                  var field_name = this.element.attr('name').split('[')[0];
                  var base_url = '/vbsearch/autocomplete/';
                  var url = base_url + request.term;

                  if (field_id != 'edit-keys' && field_id != 'edit-search-block-form--2') {
                    var url = base_url + request.term + '/' + field_name;
                  }

                  if(VectorBaseSearch.data.xhr && VectorBaseSearch.data.xhr.readyState != 4) {
                    VectorBaseSearch.data.xhr.abort();
                  }

                  VectorBaseSearch.data.xhr = $.ajax({
                    url: url, type: "GET", dataType: "json",
                    success: function (data) {
                      response(data);
                    }
                  })
                }
              });
            };

            $(document).ready(function () {
              VectorBaseSearch.init_autocomplete();
            });
          })(window.VectorBaseSearch = window.VectorBaseSearch || {}, $);
        } 
      </script>     
    \;       

    return qq{
      <div id="block-search-form">
        <form id="vb-search" method="get" action="$search_url">
          <input name="site" value="vectorbase" type="hidden">
          <input class="vb-search-keywords" name="q" value="" size="25" type="text" maxlength="128" placeholder="Search VectorBase" title="Enter the terms you wish to search for." />
          <input class="vb-search-submit" value="Go" type="submit" />
        </form>
        <p><a href="/search/site/%2A?as=True">Advanced search</a></p>
      </div>
      $js
    };
}

1;
