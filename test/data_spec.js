const neatCSV = require('neat-csv')

Cypress.on('test:after:run', (attributes) => {
  console.log('Test "%s" has finished in %dms', attributes.title, attributes.duration)
})

describe('CSV', () => {
  let table
  it('Check table info correct', ()=> {
    cy.visit('/');
    cy.wait(1000); //ensure sufficient time for page to loaded entirely and q process to save updated CSV file 

    cy.readFile('data/newtrades.csv')
    .then(neatCSV)
    .then((data) => {
      table = data;
      cy.log(table.length);
      var i = 0;
      // do all of the testing immediately after reading CSV file, so that there's less time for the website to change data in between this.
      // NOTE: I had some issues writing checksum like tests, due to variable scope issues. This suffices for now, may refractor
      cy.get('table').get('tr').each(elem => {
        if (elem.find("td:eq(3)").text() !== "" && elem.find("td:eq(4)").text() !== "") {
          //cy.log("client price: " + elem.find("td:eq(3)").text() + ", CSV price: " + table[i]['price']);
          //cy.log("client volume: " + elem.find("td:eq(4)").text() + ", CSV volume: " + table[i]['volume']);

          // test that price and volume values are indeed the same
          expect(parseFloat(elem.find("td:eq(3)").text())).to.equal(parseFloat(table[i]['price']));
          expect(parseFloat(elem.find("td:eq(4)").text())).to.equal(parseFloat(table[i]['volume']));
          expect(i).to.be.lessThan(table.length);
          i++;
        }
      });
    }); 

  });
});
