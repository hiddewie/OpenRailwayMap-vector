/**
 * The tests below should contain no cy.wait(...)
 * but there is no wait to make cypress wait for map load events.
 */
describe('home page', () => {
  it('switching layers', () => {
    cy.visit('/#view=9.88/52.5134/13.4024&')

    cy.contains('Infrastructure').click()
    cy.url().should('include', 'style=standard')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('Speed').click()
    cy.url().should('include', 'style=speed')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('Train protection').click()
    cy.url().should('include', 'style=signals')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('Electrification').click()
    cy.url().should('include', 'style=electrification')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('Gauge').click()
    cy.url().should('include', 'style=gauge')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('Loading gauge').click()
    cy.url().should('include', 'style=loading_gauge')

    cy.contains('Track class').click()
    cy.url().should('include', 'style=track_class')

    cy.wait(3000)
    cy.screenshot()
  })

  it('legend', () => {
    cy.visit('/#view=9.88/52.5134/13.4024&')

    // Open legend
    cy.contains('Legend').click()

    // TODO assert legend
    cy.wait(3000)
    cy.screenshot()

    // Close legend
    cy.contains('Legend').click()
  })

  it('search', () => {
    cy.visit('/#view=9.88/52.5134/13.4024&')

    cy.get('button').contains('Search').click()

    cy.get('input[type=search]').type('berlin{enter}')

    cy.contains('Zoologischer Garten').click()

    cy.wait(3000)
    cy.screenshot()
  })

  it('search, show on map', () => {
    cy.visit('/#view=9.88/52.5134/13.4024&')

    cy.get('button').contains('Search').click()

    cy.get('input[type=search]').type('berlin{enter}')

    cy.contains('Show on map').click()

    cy.wait(3000)
    cy.screenshot()
  })

  it('settings', () => {
    cy.visit('/#view=9.88/52.5134/13.4024&')

    cy.get('.maplibregl-ctrl-configuration').click()

    cy.wait(3000)
    cy.screenshot()
  })
})
