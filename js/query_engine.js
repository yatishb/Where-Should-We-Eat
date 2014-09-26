query = new QueryEngine();

function QueryEngine(){

  this.resultDisplay;

  this.partyCost;

  this.updateSearchResults = function(results){
    this.resultDisplay.updateSearchResults(results);
  }

  this.refresh = function(){
    console.log('Refreshing');
    this.resultDisplay.clearMap();
    this.resultDisplay = new ResultDisplay(this.resultDisplay.returnMap());
  }

}

$(document).ready(function(){

  $(document).on('pagecontainerbeforeshow', function( event, ui){
    //console.log('Herp');
    if($(ui.toPage).attr('id') === 'NewConquestOne') {
        if(query && query.resultDisplay){query.refresh()};
      }
  });

});
