/**
 * The tests below should contain no cy.wait(...)
 * but there is no wait to make cypress wait for map load events.
 */
describe('home page', () => {
  it('switching style (light mode)', () => {
    cy.visit('/#view=9.88/52.5134/13.4024&')

    cy.contains('.maplibregl-ctrl-preset button', 'Presets').click()

    cy.contains('.maplibregl-ctrl-preset button', 'Infrastructure').click()
    cy.url().should('not.include', 'tracks=usage')

    cy.wait(3000)
    cy.screenshot()

    cy.get('.maplibregl-ctrl-date input[type=range]').invoke('val', 1947).trigger('input').trigger('change')
    cy.get('.date-display').should('have.value', '1947')
    cy.url().should('include', 'date=1947')

    cy.wait(3000)
    cy.screenshot()

    cy.get('.maplibregl-ctrl-date input[type=range]').invoke('val', (new Date()).getFullYear()).trigger('input').trigger('change')
    cy.get('.date-display').should('have.value', 'present')
    cy.url().should('not.include', 'date=')

    cy.contains('.maplibregl-ctrl-preset button', 'Speed').click()
    cy.url().should('include', 'tracks=speed')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-preset button', 'Train protection').click()
    cy.url().should('include', 'tracks=train_protection')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-preset button', 'Electrification').click()
    cy.url().should('include', 'tracks=electrification')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-preset button', 'Track').click()
    cy.url().should('include', 'tracks=track')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-preset button', 'Operator').click()
    cy.url().should('include', 'tracks=operator')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-preset button', 'Routes').click()
    cy.url().should('include', 'tracks=routes')

    cy.wait(3000)
    cy.screenshot()
  })

  it('switching style (dark mode)', () => {
    cy.visit('/#view=9.88/52.5134/13.4024&')

    cy.get('.maplibregl-ctrl-configuration').click()
    cy.contains('Map configuration').should('be.visible')
    cy.get('label').contains('Dark').click()

    cy.screenshot()

    cy.get('#configuration-backdrop .btn-close').click()
    cy.contains('Map configuration').should('not.be.visible')
    cy.url().should('not.include', 'tracks=usage')

    cy.wait(3000)
    cy.screenshot()

    cy.get('.maplibregl-ctrl-date input[type=range]').invoke('val', 1947).trigger('input').trigger('change')
    cy.get('.date-display').should('have.value', '1947')
    cy.url().should('include', 'date=1947')

    cy.wait(3000)
    cy.screenshot()

    cy.get('.maplibregl-ctrl-date input[type=range]').invoke('val', (new Date()).getFullYear()).trigger('input').trigger('change')
    cy.get('.date-display').should('have.value', 'present')
    cy.url().should('not.include', 'date=')

    cy.contains('.maplibregl-ctrl-preset button', 'Presets').click()

    cy.contains('.maplibregl-ctrl-preset button', 'Speed').click()
    cy.url().should('include', 'tracks=speed')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-preset button', 'Train protection').click()
    cy.url().should('include', 'tracks=train_protection')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-preset button', 'Electrification').click()
    cy.url().should('include', 'tracks=electrification')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-preset button', 'Track').click()
    cy.url().should('include', 'tracks=track')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-preset button', 'Operator').click()
    cy.url().should('include', 'tracks=operator')

    cy.wait(3000)
    cy.screenshot()

    cy.contains('.maplibregl-ctrl-preset button', 'Routes').click()
    cy.url().should('include', 'tracks=routes')

    cy.wait(3000)
    cy.screenshot()
  })

  it('legend', () => {
    cy.visit('/#view=9.88/52.5134/13.4024&')

    // Open legend
    cy.contains('button.maplibregl-ctrl-legend', 'Legend').click()

    // TODO assert legend
    cy.wait(3000)
    cy.screenshot()

    // Close legend
    cy.contains('button.maplibregl-ctrl-legend', 'Legend').click()
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
