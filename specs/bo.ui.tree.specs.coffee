#reference "/assets/js/blackout/bo.ui.tree.coffee"

describe "bo.tree", ->
    describe "When creating tree ViewModel with no option overrides", ->
        tree = new bo.ui.Tree()
    
        it "creates an open root node", ->
            expect(tree.root.isOpen()).toBe true

        it "creates a non-deletable root node", ->
            expect(tree.root.canDelete).toBe false

        it "creates a selectedNode observable that is null", ->
            expect(ko.isObservable(tree.selectedNode)).toBe true
            expect(tree.selectedNode()).toBeNull()
        
    describe "When creating node with children array", ->
        children = [{ name: 'Node1' }, { name: 'Node2' }]
        tree = new bo.ui.Tree({ root: { children: children }})
    
        it "loads sets children loaded property to true", ->
            expect(tree.root.children.loaded()).toBe true

        it "converts children into child tree nodes on creation", ->
            expect(tree.root.children()[0].name()).toBe "Node1"
            expect(tree.root.children()[1].name()).toBe "Node2"
        
    describe "When creating node that is not already open with loadChildren function", ->
        loadChildren = (callback) -> callback([{ name: 'Node1' }, { name: 'Node2' }])
        tree = null
        
        beforeEach ->
            tree = new bo.ui.Tree({ root: { loadChildren: loadChildren, isOpen: false }})

        it "does not immediately load children", ->
            expect(tree.root.children.loaded()).toBe false
            
        it "has an empty array as children observable", ->
            expect(tree.root.children().length).toBe 0
                        
        it "loads children when opened", ->
            tree.root.open()
            
            expect(tree.root.children.loaded()).toBe true
            expect(tree.root.children().length).toBe 2
                        
        it "loads children when folder toggled (toggleFolder)", ->
            tree.root.toggleFolder()
            
            expect(tree.root.children.loaded()).toBe true
            expect(tree.root.children().length).toBe 2
        
    describe "When selecting nodes", ->
        children = [{ name: 'Node1' }, { name: 'Node2' }]
        tree = new bo.ui.Tree({ root: { children: children }})
    
        it "sets the node as selected", ->
            tree.root.children()[0].select()

            expect(tree.root.children()[0].isSelected()).toBe true

        it "sets the node as focused", ->
            tree.root.children()[0].select()

            expect(tree.root.children()[0].isFocused()).toBe true
    
        it "sets the viewModel selectedNode observable", ->
            tree.root.children()[0].select()

            expect(tree.selectedNode().name()).toBe "Node1"		
    
        it "sets selected to false on any previously selected node", ->
            tree.root.children()[0].select()
            tree.root.children()[1].select()
        
            expect(tree.root.children()[0].isSelected()).toBe false
            expect(tree.root.children()[1].isSelected()).toBe true
                    
    describe "When focusing nodes", ->
        children = [{ name: 'Node1' }, { name: 'Node2' }]
        tree = new bo.ui.Tree({ root: { children: children }})
    
        it "sets the node as focused", ->
            tree.root.children()[0].focus()

            expect(tree.root.children()[0].isFocused()).toBe true
