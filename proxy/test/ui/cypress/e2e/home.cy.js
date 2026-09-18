/**
 * The tests below should contain no cy.wait(...)
 * but there is no wait to make cypress wait for map load events.
 */
describe('home page', () => {
  it('switching presets (light mode)', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    cy.contains('.maplibregl-ctrl-preset button', 'Presets').click()

    cy.contains('.maplibregl-ctrl-preset button', 'Infrastructure').click()
    cy.url().should('not.include', 'tracks=')

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

  it('switching style, tracks', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    const button = cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Tracks')
    button.click()
    button.get('.maplibregl-ctrl-style-popup-container').should('be.visible')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Tracks')
      .contains('button', 'Usage')
      .click()

    cy.url().should('not.include', 'tracks=')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Tracks')
      .contains('button', 'Speed')
      .click()

    cy.url().should('include', 'tracks=speed')


    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Tracks')
      .contains('button', 'Train protection')
      .click()

    cy.url().should('include', 'tracks=train_protection')


    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Tracks')
      .contains('button', 'Voltage & frequency')
      .click()

    cy.url().should('include', 'tracks=voltage_frequency')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Tracks')
      .contains('button', 'Maximum current')
      .click()

    cy.url().should('include', 'tracks=maximum_current')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Tracks')
      .contains('button', 'Electrical power')
      .click()

    cy.url().should('include', 'tracks=power')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Tracks')
      .contains('button', 'Track')
      .click()

    cy.url().should('include', 'tracks=track')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Tracks')
      .contains('button', 'Operator')
      .click()

    cy.url().should('include', 'tracks=operator')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Tracks')
      .contains('button', 'Routes')
      .click()

    cy.url().should('include', 'tracks=routes')
  })

  it('switching style, operating sites', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    const button = cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Operating sites')
    button.click()
    button.get('.maplibregl-ctrl-style-popup-container').should('be.visible')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Operating sites')
      .contains('button', 'Modality')
      .click()

    cy.url().should('not.include', 'stations=')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Operating sites')
      .contains('button', 'Operator')
      .click()

    cy.url().should('include', 'stations=operator')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Operating sites')
      .contains('button', 'None')
      .click()

    cy.url().should('include', 'stations=none')
  })

  it('switching style, platforms', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    const button = cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Platforms')
    button.click()
    button.get('.maplibregl-ctrl-style-popup-container').should('be.visible')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Platforms')
      .contains('button', 'Plain')
      .click()

    cy.url().should('not.include', 'platforms=')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Platforms')
      .contains('button', 'None')
      .click()

    cy.url().should('include', 'platforms=none')
  })

  it('switching style, switches', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    const button = cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Switches')
    button.click()
    button.get('.maplibregl-ctrl-style-popup-container').should('be.visible')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Switches')
      .contains('button', 'Plain')
      .click()

    cy.url().should('not.include', 'switches=')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Switches')
      .contains('button', 'None')
      .click()

    cy.url().should('include', 'switches=none')
  })

  it('switching style, signals', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    const button = cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Signals')
    button.click()
    button.get('.maplibregl-ctrl-style-popup-container').should('be.visible')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Signals')
      .contains('button', 'Speed')
      .click()

    cy.url().should('include', 'signals=speed')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Signals')
      .contains('button', 'Train protection')
      .click()

    cy.url().should('include', 'signals=signals')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Signals')
      .contains('button', 'Electrification')
      .click()

    cy.url().should('include', 'signals=electrification')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Signals')
      .contains('button', 'None')
      .click()

    cy.url().should('not.include', 'signals=')
  })

  it('switching style, points of interest', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    const button = cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Points of interest')
    button.click()
    button.get('.maplibregl-ctrl-style-popup-container').should('be.visible')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Points of interest')
      .contains('button', 'Standard')
      .click()

    cy.url().should('not.include', 'pois=')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Points of interest')
      .contains('button', 'Electrification')
      .click()

    cy.url().should('include', 'pois=electrification')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Points of interest')
      .contains('button', 'Signals')
      .click()

    cy.url().should('include', 'pois=signals')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Points of interest')
      .contains('button', 'Operator')
      .click()

    cy.url().should('include', 'pois=operator')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Points of interest')
      .contains('button', 'None')
      .click()

    cy.url().should('include', 'pois=none')
  })

  it('switching style, turntables', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    const button = cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Turntables')
    button.click()
    button.get('.maplibregl-ctrl-style-popup-container').should('be.visible')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Turntables')
      .contains('button', 'Plain')
      .click()

    cy.url().should('not.include', 'turntables=')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Turntables')
      .contains('button', 'None')
      .click()

    cy.url().should('include', 'turntables=none')
  })

  it('switching style, turntables', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    const button = cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Boxes')
    button.click()
    button.get('.maplibregl-ctrl-style-popup-container').should('be.visible')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Boxes')
      .contains('button', 'Plain')
      .click()

    cy.url().should('include', 'boxes=plain')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Boxes')
      .contains('button', 'Operator')
      .click()

    cy.url().should('include', 'boxes=operator')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Boxes')
      .contains('button', 'None')
      .click()

    cy.url().should('not.include', 'boxes=')
  })

  it('switching style, substations', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    const button = cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Substations')
    button.click()
    button.get('.maplibregl-ctrl-style-popup-container').should('be.visible')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Substations')
      .contains('button', 'Plain')
      .click()

    cy.url().should('include', 'substations=plain')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Substations')
      .contains('button', 'None')
      .click()

    cy.url().should('not.include', 'substations=')
  })

  it('switching style, catenaries', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    const button = cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Catenaries')
    button.click()
    button.get('.maplibregl-ctrl-style-popup-container').should('be.visible')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Catenaries')
      .contains('button', 'Plain')
      .click()

    cy.url().should('include', 'catenaries=plain')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Catenaries')
      .contains('button', 'Operator')
      .click()

    cy.url().should('include', 'catenaries=operator')

    cy.contains('.maplibregl-ctrl-style .maplibregl-ctrl-style-popup-button', 'Catenaries')
      .contains('button', 'None')
      .click()

    cy.url().should('not.include', 'catenaries=')
  })

  it('switching presets (dark mode)', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    cy.get('.maplibregl-ctrl-configuration').click()
    cy.contains('Map configuration').should('be.visible')
    cy.get('label').contains('Dark').click()

    cy.screenshot()

    cy.get('#configuration-backdrop .btn-close').click()
    cy.contains('Map configuration').should('not.be.visible')
    cy.url().should('not.include', 'tracks=')

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
    cy.visit('/#view=9.88/52.5134/13.4024')

    // Open legend
    cy.contains('button.maplibregl-ctrl-legend', 'Legend').click()

    // TODO assert legend
    cy.wait(3000)
    cy.screenshot()

    // Close legend
    cy.contains('button.maplibregl-ctrl-legend', 'Legend').click()
  })

  it('search', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    cy.get('button').contains('Search').click()

    cy.get('input[type=search]').type('berlin{enter}')

    cy.contains('Berlin Hauptbahnhof').click()

    cy.wait(3000)
    cy.screenshot()
  })

  it('search, show on map', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    cy.get('button').contains('Search').click()

    cy.get('input[type=search]').type('berlin{enter}')

    cy.contains('Show on map').click()

    cy.wait(3000)
    cy.screenshot()
  })

  it('settings', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    cy.get('.maplibregl-ctrl-configuration').click()

    cy.contains('Map configuration').should('be.visible')
    cy.screenshot()
  })

  it('news', () => {
    cy.visit('/#view=9.88/52.5134/13.4024')

    cy.get('.maplibregl-ctrl-news').click()

    cy.contains('News').should('be.visible')
    cy.screenshot()
  })
})
