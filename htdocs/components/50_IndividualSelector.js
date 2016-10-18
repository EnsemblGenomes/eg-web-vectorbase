Ensembl.Panel.IndividualSelector = Ensembl.Panel.extend({
  
  constructor: function (id, params) {
    this.base.apply(this, arguments);
  },
  
  init: function () {
    this.base.apply(this, arguments);
    var panel = this;

    $('.button', panel.el).click( function() {
      var checked = $('table input:checkbox', panel.el).prop('checked');
      $('table input:checkbox', panel.el).prop('checked', checked ? false : true); 
      return false;
    });
  }
});
  