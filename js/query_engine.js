query = new QueryEngine();

function QueryEngine(){

  this.resultDisplay;

  this.updateSearchResults = function(results){
    this.resultDisplay.updateSearchResults(results);
  }

  this.refresh = function(){
    this.resultDisplay.clearMap();
    this.resultDisplay = new ResultDisplay(this.resultDisplay.returnMap());
  }

}

$(document).ready(function(){

  $(document).on('pagecontainerbeforeshow', function( event, ui){
    //console.log('Herp');
    if($(ui.toPage).attr('id') === 'NewConquestOne') {
        query.refresh();
      }
  });

});
