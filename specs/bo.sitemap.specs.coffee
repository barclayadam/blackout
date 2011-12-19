#reference "../../js/blackout/bo.sitemap.coffee"

describe 'Sitemap', ->
    describe 'When creating a new sitemap', ->
        it 'should create an currentNode observable set to undefined', ->
            # Act
            regionManager = new bo.RegionManager()
            sitemap = new bo.Sitemap regionManager,
                'Home':
                    url: '/'

            # Assert
            expect(sitemap.currentNode).toBeObservable()
            expect(sitemap.currentNode()).toBeUndefined()

        it 'should have a breadcrumb observable set to an empty array', ->
            # Act
            regionManager = new bo.RegionManager()
            sitemap = new bo.Sitemap regionManager,
                'Home':
                    url: '/'

            # Assert
            expect(sitemap.breadcrumb).toBeObservable()
            expect(sitemap.breadcrumb()).toBeAnEmptyArray()
            
    describe 'When creating a sitemap with a named page', ->
        it 'should create a new route with name of node and url', ->
            # Act
            regionManager = new bo.RegionManager()
            sitemap = new bo.Sitemap regionManager,
                'Home':
                    url: '/'

            # Assert
            expect("routeCreated:Home").toHaveBeenPublished()

        it 'should have a hasRoute property set to true if url is defined', ->
            # Act
            regionManager = new bo.RegionManager()
            sitemap = new bo.Sitemap regionManager,
                'Home':
                    url: '/'

            # Assert
            expect(sitemap.nodes[0].hasRoute).toBe true

        it 'does not register a route if no url is defined', ->
            # Act
            regionManager = new bo.RegionManager()
            sitemap = new bo.Sitemap regionManager,
                'Home':
                    inNavigation: true

            # Assert
            expect("routeCreated:Home").toHaveNotBeenPublished()

        it 'should have a hasRoute property set to false if no url is defined', ->
            # Act
            regionManager = new bo.RegionManager()
            sitemap = new bo.Sitemap regionManager,
                'Home':
                    inNavigation: true

            # Assert
            expect(sitemap.nodes[0].hasRoute).toBe false

        it 'registers page as a sitemap node', ->
            # Act
            regionManager = new bo.RegionManager()
            sitemap = new bo.Sitemap regionManager,
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

            # Assert
            expect(sitemap.nodes[0]).toBeDefined()
            expect(sitemap.nodes[0].name).toEqual 'Home'          

        it 'creates sitemap nodes with path set-up correctly', ->
            # Act
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

            # Assert
            expect(sitemap.nodes[0].getAncestorsAndThis()[0].name).toEqual 'Home'

        it 'should create a single root node', ->
            # Act
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]
                    isInNavigation: false

            # Assert
            expect(sitemap.nodes.length).toEqual 1            

    describe 'When creating a sitemap with node that has isInNavigation property', ->
        it 'creates a node with isVisible observable set to value of isInNavigation property', ->
            # Act
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]
                    isInNavigation: false

            # Assert
            expect(sitemap.nodes[0].isVisible()).toEqual false

        it 'creates a node with isVisible observable set to isInNavigation observable', ->
            # Arrange
            inNavigationObservable = ko.observable true

            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]
                    isInNavigation: inNavigationObservable
                    
            expect(sitemap.nodes[0].isVisible()).toEqual true

            # Act
            inNavigationObservable false

            # Assert
            expect(sitemap.nodes[0].isVisible()).toEqual false

        it 'should activate registered parts when navigating to route', ->
            # Arrange
            homeParts = [new bo.Part 'My Shiny Part']
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: homeParts

            # Act
            bo.bus.publish 'routeNavigated:Home'

            # Assert
            expect("partsActivating").toHaveBeenPublishedWith { parts: homeParts }

        it 'should set currentNode to be the sitemap node defined with route when navigating to route', ->
            # Arrange
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

            # Act
            bo.bus.publish 'routeNavigated:Home'

            # Assert
            expect(sitemap.currentNode().name).toEqual 'Home'

        it 'should set isCurrent on node with route navigated to', ->
            # Arrange
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

            # Act
            bo.bus.publish 'routeNavigated:Home'

            # Assert
            expect(sitemap.nodes[0].isCurrent()).toEqual true

        it 'should set isCurrent to false when navigated away from a route', ->
            # Arrange
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

                'Contact Us':
                    url: '/Contact Us'
                    parts: [new bo.Part 'My Other Shiny Part' ]

            bo.bus.publish 'routeNavigated:Home'
            expect(sitemap.nodes[0].isCurrent()).toEqual true

            # Act
            bo.bus.publish 'routeNavigated:Contact Us'

            # Assert
            expect(sitemap.nodes[0].isCurrent()).toEqual false

        it 'should have a breadcrumb observable of current node when route navigated to', ->
            # Arrange
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

            # Act
            bo.bus.publish 'routeNavigated:Home'

            # Assert
            expect(sitemap.breadcrumb()[0].name).toEqual 'Home'

        it 'should mark node node as active', ->
            # Arrange
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

            # Act
            bo.bus.publish 'routeNavigated:Home'

            # Assert
            expect(sitemap.nodes[0].isActive()).toBe true

    describe 'When creating a sitemap with multiple levels', ->
        it 'should register sub items when defined', ->
            # Act
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

                    'Contact Us':
                        url: '/Contact Us'
                        parts: [new bo.Part 'My Shiny Contact Us Part' ]

            # Assert
            expect("routeCreated:Contact Us").toHaveBeenPublished()

        it 'should return true to hasChildren of parent node', ->
            # Act
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

                    'Contact Us':
                        url: '/Contact Us'
                        parts: [new bo.Part 'My Shiny Contact Us Part' ]

            # Assert
            expect(sitemap.nodes[0].hasChildren()).toBe true

        it 'should return false to hasChildren of parent node if no visible children', ->
            # Act
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

                    'Contact Us':
                        url: '/Contact Us'
                        parts: [new bo.Part 'My Shiny Contact Us Part' ],

                        isInNavigation: false

            # Assert
            expect(sitemap.nodes[0].hasChildren()).toBe false

        it 'should create the count of root nodes, with exact number of sub-nodes', ->
            # Act
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]
                    isInNavigation: false

                    'Contact Us':
                        url: '/Contact Us'
                        parts: [new bo.Part 'My Shiny Contact Us Part' ]
                        isInNavigation: false

            # Assert
            expect(sitemap.nodes.length).toEqual 1    
            expect(sitemap.nodes[0].children().length).toEqual 1                     

        it 'should create sitemap nodes with path set-up correctly', ->
            # Act
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

                    'Contact Us':
                        url: '/Contact Us'
                        parts: [new bo.Part 'My Shiny Contact Us Part' ]

            # Assert
            expect(sitemap.nodes[0].getAncestorsAndThis()[0].name).toEqual 'Home'

            expect(sitemap.nodes[0].children()[0].getAncestorsAndThis()[0].name).toEqual 'Home'
            expect(sitemap.nodes[0].children()[0].getAncestorsAndThis()[1].name).toEqual 'Contact Us'

        it 'should have a breadcrumb observable of current node\'s full path when route navigated to', ->
            # Arrange
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

                    'Contact Us':
                        url: '/Contact Us'
                        parts: [new bo.Part 'My Shiny Contact Us Part' ]

            # Act
            bo.bus.publish 'routeNavigated:Contact Us'

            # Assert
            expect(sitemap.breadcrumb()[0].name).toEqual 'Home'
            expect(sitemap.breadcrumb()[1].name).toEqual 'Contact Us'

        it 'should mark all nodes in the breadcrumb path as active', ->
            # Arrange
            sitemap = new bo.Sitemap new bo.RegionManager(),
                'Home':
                    url: '/'
                    parts: [new bo.Part 'My Shiny Part' ]

                    'Contact Us':
                        url: '/Contact Us'
                        parts: [new bo.Part 'My Shiny Contact Us Part' ]

            # Act
            bo.bus.publish 'routeNavigated:Contact Us'

            # Assert
            expect(sitemap.nodes[0].isActive()).toBe true
            expect(sitemap.nodes[0].children()[0].isActive()).toBe true
