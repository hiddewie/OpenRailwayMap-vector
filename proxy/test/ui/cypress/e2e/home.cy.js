/**
 * The tests below should contain no cy.wait(...)
 * but there is no wait to make cypress wait for map load events.
 */
describe('home page', () => {
  it('switching layers (light mode)', () => {
    cy.visit('/#view=9.88/52.5134/13.4024&')

    cy.contains('.maplibregl-ctrl-style button', 'Infrastructure').click()
    cy.url().should('not.include', 'style=standard')

    cy.wait(3000)
    cy.screenshot()

    cy.get('.maplibregl-ctrl-date input[type=range]').invoke('val', 1947).trigger('input').trigger('change')
    cy.get('.date-display').should('include.text', '1947')
    cy.url().should('include', 'date=1947')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-style button', 'Speed').click()
    cy.url().should('include', 'style=speed')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-style button', 'Train protection').click()
    cy.url().should('include', 'style=signals')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-style button', 'Electrification').click()
    cy.url().should('include', 'style=electrification')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-style button', 'Track').click()
    cy.url().should('include', 'style=track')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-style button', 'Operator').click()
    cy.url().should('include', 'style=operator')

    cy.contains('.maplibregl-ctrl-style button', 'Radio Type').click()
    cy.url().should('include', 'style=radio')

    cy.wait(3000)
    cy.screenshot()
  })

  it('switching layers (dark mode)', () => {
    cy.visit('/#view=9.88/52.5134/13.4024&')

    cy.get('.maplibregl-ctrl-configuration').click()
    cy.contains('Map configuration').should('be.visible')
    cy.get('label').contains('Dark').click()

    cy.screenshot()

    cy.get('#configuration-backdrop .btn-close').click()
    cy.contains('Map configuration').should('not.be.visible')
    cy.url().should('not.include', 'style=standard')

    cy.wait(3000)
    cy.screenshot()

    cy.get('.maplibregl-ctrl-date input[type=range]').invoke('val', 1947).trigger('input').trigger('change')
    cy.get('.date-display').should('include.text', '1947')
    cy.url().should('include', 'date=1947')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-style button', 'Speed').click()
    cy.url().should('include', 'style=speed')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-style button', 'Train protection').click()
    cy.url().should('include', 'style=signals')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-style button', 'Electrification').click()
    cy.url().should('include', 'style=electrification')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-style button', 'Track').click()
    cy.url().should('include', 'style=track')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-style button', 'Operator').click()
    cy.url().should('include', 'style=operator')

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

    cy.contains('Berlin Hauptbahnhof').click()

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

    cy.contains('Map configuration').should('be.visible')
    cy.screenshot()
  })

  it('news', () => {
    cy.visit('/#view=9.88/52.5134/13.4024&')

    cy.get('.maplibregl-ctrl-news').click()

    cy.contains('News').should('be.visible')
    cy.screenshot()
  })
})
