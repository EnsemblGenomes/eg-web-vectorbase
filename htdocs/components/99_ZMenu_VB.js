Ensembl.Panel.ZMenu = Ensembl.Panel.ZMenu.extend({
  _populateRegion: function () {
    var panel        = this;
    var min          = this.start;
    var max          = this.end;
    var locationView = !!window.location.pathname.match('/Location/') && !window.location.pathname.match(/\/(Chromosome|Synteny)/);
    var scale        = (max - min + 1) / (this.areaCoords.r - this.areaCoords.l);
    var url          = this.baseURL;
    var menu, caption, start, end, tmp, cls;
    
    // Gene, transcript views
    function notLocation() {
      var view = end - start + 1 > Ensembl.maxRegionLength ? 'Overview' : 'View';
          url  = url.replace(/.+\?/, '?');
          menu = [ '<a href="' + panel.speciesPath + '/Location/' + view + url + '">Jump to location ' + view.toLowerCase() + '</a>' ];
//// EG - ENSEMBL-3311 disable confusing link      
      // if (!window.location.pathname.match('/Chromosome')) {
      //   menu.push('<a href="' + panel.speciesPath + '/Location/Chromosome' + url + '">Chromosome summary</a>');
      // }
////      
    }
    
    // Multi species view
    function multi() {
      var label = start ? 'region' : 'location';
          menu  = [ '<a href="' + url.replace(/;action=primary;id=\d+/, '') + '">Realign using this ' + label + '</a>' ];
        
      if (panel.multi) {
        menu.push('<a href="' + url + '">Use ' + label + ' as primary</a>');
      } else {
        menu.push('<a href="' + url.replace(/[rg]\d+=[^;]+;?/g, '') + '">Jump to ' + label + '</a>');
      }
    
      caption = panel.species.replace(/_/g, ' ') + ' ' + panel.chr + ':' + (start ? start + '-' + end : panel.location);
    }
    
    // AlignSlice view
    function align() {
      var label  = start ? 'region' : 'location';
          label += panel.species === Ensembl.species ? '' : ' on ' + Ensembl.species.replace(/_/g, ' ');
      
      menu    = [ '<a href="' + url.replace(/%s/, Ensembl.coreParams.r + ';align_start=' + start + ';align_end=' + end) + '">Jump to best aligned ' + label + '</a>' ];
      caption = 'Alignment: ' + (start ? start + '-' + end : panel.location);
    }
    
    // Region select
    if (this.coords.r) {
      start = Math.floor(min + (this.coords.s - this.areaCoords.l) * scale);
      end   = Math.floor(min + (this.coords.s + this.coords.r - this.areaCoords.l) * scale);
      
      if (start > end) {
        tmp   = start;
        start = end;
        end   = tmp;
      }
      
      start = Math.max(start, min);
      end   = Math.min(end,   max);
      
      if (this.strand === 1) {
        this.location = (start + end) / 2;
      } else {
        this.location = (2 * this.start + 2 * this.end - start - end) / 2;
        
        tmp   = start;
        start = this.end + this.start - end;
        end   = this.end + this.start - tmp;
      }
      
      if (this.align === true) {
        align();
      } else {
        url     = url.replace(/%s/, this.chr + ':' + start + '-' + end);
        caption = 'Region: ' + this.chr + ':' + start + '-' + end;
        
        if (!locationView) {
          notLocation();
        } else if (this.multi !== false) {
          multi();
        } else {
          cls = 'location_change';
          
          if (end - start + 1 > Ensembl.maxRegionLength) {
            if (url.match('/View')) {
              url = url.replace('/View', '/Overview');
              cls = '';
            }
          }
          
          menu = [ '<a class="' + cls + '" href="' + url + '">Jump to region (' + (end - start + 1) + ' bp)</a>' ];
//// VB - add web apollo link 
          if ( $('#webapollo-url').length ) {
            menu.push('<a class="center constant" href="%">View region in WebApollo</a>'.replace('%', 
              $('#webapollo-url').val().replace('%', this.chr).replace('%', start).replace('%', end) 
            ));
          }
////   

        }
      }
    } else { // Point select
      this.location = Math.floor(min + (this.coords.x - this.areaCoords.l) * scale);
      
      if (this.align === true) {
        url = this.zoomURL(1/10);
        align();
      } else {
        url     = this.zoomURL(1);
        caption = 'Location: ' + this.chr + ':' + this.location;
        
        if (!locationView) {
          notLocation();
        } else if (this.multi !== false) {
          multi();
        } else {
          menu = [
            '<a class="location_change" href="' + this.zoomURL(10) + '">Zoom out x10</a>',
            '<a class="location_change" href="' + this.zoomURL(5)  + '">Zoom out x5</a>',
            '<a class="location_change" href="' + this.zoomURL(2)  + '">Zoom out x2</a>',
            '<a class="location_change" href="' + url + '">Centre here</a>'
          ];
          
          // Only add zoom in links if there is space to zoom in to.
          $.each([2, 5, 10], function () {
            var href = panel.zoomURL(1 / this);
            
            if (href !== '') {
              menu.push('<a class="location_change" href="' + href + '">Zoom in x' + this + '</a>');
            }
          });
        }
      }
    }
    
    this.buildMenu(menu, caption);
  },

  // revert to original Ensembl behaviour 
  populateNoAjax: function (force) {
    var oldest = Ensembl.Panel.ZMenu.ancestor;
    while (oldest.ancestor && typeof oldest.ancestor.prototype.populateNoAjax === 'function') {
      oldest = oldest.ancestor;
    }
    return oldest.prototype.populateNoAjax.apply(this, arguments);
  }

}, { template: Ensembl.Panel.ZMenu.template });