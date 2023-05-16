import GameplayKit
import UserNotifications

class GameScene: SKScene, SKPhysicsContactDelegate {
    enum ButtonAssociation {
        case movementAnalog
        case combosAnalog
    }
    
    init(background backgroundFileName: String, enemiesQtd: Int, levelMapFile: String, size: CGSize) {
        self.background = SKSpriteNode(texture: SKTexture(imageNamed: backgroundFileName))
        self.numberEnemies = enemiesQtd
        let a = CGRect(origin: CGPoint.zero, size: size)
        Constants.setFrame(a)
        self.mapInterpreter = MapInterpreter(map: a, platformHeightDistance: Constants.singleton.playerSize.height + 60, platformHeight: Constants.singleton.platformsHeight, scale: 3, mapText: levelMapFile)!
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private var platforms: [SKSpriteNode] = []
    private var player: Player = Player(sprite: "")
    private var spiders: [EnemySpider] = []
    private var magics: [MagicProjetile] = []
    
    private var background = SKSpriteNode(texture: SKTexture(imageNamed: "MainScene"))
    
    private var touches: [(UITouch, ButtonAssociation)] = []
    
    private var movementInput = SKShapeNode()
    private var movementAnalogic = SKShapeNode()
    
    private var combosInput = SKShapeNode()
    private var combosInputThreshold = SKShapeNode()
    private var combosAnalogic = SKShapeNode()
    
    private var numberEnemies = Int.random(in: 1..<5)
    
    private var directionsCombos: [Directions] = []
    private var directionsMovement: [Directions] = []
    
    private var jumpCounter = 0
    
    private var mapInterpreter: MapInterpreter
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera = camera else { return }
        
        for t in touches {
            let pos = t.location(in: camera)
            
            if movementInput.contains(pos) {
                movementAnalogic.run(SKAction.move(to: pos, duration: 0.1))
                self.touches.append((t, .movementAnalog))
            }
            
            if combosInput.contains(pos) {
                self.touches.append((t, .combosAnalog))
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera = camera else { return }

        for t in self.touches {
            
            let pos = t.0.location(in: camera)
            
            switch t.1 {
            case .movementAnalog:
                handleMovement(start: movementInput.position, pos: pos)
                
                if movementInput.contains(pos) {
                    movementAnalogic.run(.move(to: pos, duration: 0.1))
                } else {
                    let limitedPos = (pos - movementInput.position).normalized() * 100
                    movementAnalogic.run(.move(to: movementInput.position + limitedPos, duration: 0.1))
                }
                
            case .combosAnalog:
                if combosInput.contains(pos) {
                    combosAnalogic.run(.move(to: pos, duration: 0.1))
                } else {
                    let limitedPos = (pos - combosInput.position).normalized() * 100
                    combosAnalogic.run(.move(to: combosInput.position + limitedPos, duration: 0.1))
                }
                
                let vector = pos - combosInput.position
                let directions = Directions.calculateDirections(vector)
                
                switch directions[0] {
                case .up:
                    combosInput.children.forEach { nd in
                        emphasizeComboSprite(nd, name: "ice")
                    }
                case .left:
                    combosInput.children.forEach { nd in
                        emphasizeComboSprite(nd, name: "fire")
                    }
                case .down:
                    combosInput.children.forEach { nd in
                        emphasizeComboSprite(nd, name: "eletric")
                    }
                case .right:
                    combosInput.children.forEach { nd in
                        emphasizeComboSprite(nd, name: "earth")
                    }
                }
            }
        }
    }
    
    private func emphasizeComboSprite(_ nd: SKNode, name: String) {
        guard let ndName = nd.name else { return }
        
        if ndName == name {
            nd.run(.group([
                .scale(to: Constants.singleton.combosSpritesScale + 0.5, duration: Constants.singleton.combosSpritesAnimationDuration),
                .fadeAlpha(to: 2, duration: Constants.singleton.combosSpritesAnimationDuration)
                
            ]))
        } else {
            nd.run(.group([
                .scale(to: Constants.singleton.combosSpritesScale, duration: Constants.singleton.combosSpritesAnimationDuration),
                .fadeAlpha(to: Constants.singleton.combosSpritesAlpha, duration: Constants.singleton.combosSpritesAnimationDuration)
            ]))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera = camera else { return }
    
        self.touches = self.touches.filter({ (t, i) in
            guard touches.contains(t) else { return true }
            
            switch i {
                
            case .movementAnalog:
                movementAnalogic.run(SKAction.move(to: movementInput.position, duration: 0.1))
                
                directionsMovement = []
                
            case .combosAnalog:
                let pos = t.location(in: camera)
                
                handleCombo(start: combosInput.position, pos: pos)
                combosAnalogic.run(SKAction.move(to: combosInput.position, duration: 0.1))
                
                for i in combosInput.children {
                    i.run(.group([
                        .scale(to: Constants.singleton.combosSpritesScale, duration: Constants.singleton.combosSpritesAnimationDuration),
                        .fadeAlpha(to: Constants.singleton.combosSpritesAlpha, duration: Constants.singleton.combosSpritesAnimationDuration)
                    ]))
                }
            }
            return false
        })
    }
    
    private func handleMovement(start: CGPoint, pos: CGPoint) {
        let vector = pos - start
        
        directionsMovement = Directions.calculateDirections(vector).filter { dir in
            dir != .down
        }
    }
    
    private func handleCombo(start: CGPoint, pos: CGPoint) {
        let vector = pos - start
        let directions = Directions.calculateDirections(vector)
        if directionsCombos.count == 2 {
            let normalizedVector = vector.normalized()
            let magic = Magics.magic(primary: directionsCombos[0], secondary: directionsCombos[1])
            let angle = atan2(normalizedVector.y, normalizedVector.x)
            // MARK: call combo with vector and magic
            switch magic{
            case .A(.fire):
                let fireball = Fireball(angle: angle, player: player)
                magics.append(fireball)
                addChild(fireball.node)
            case .A(.ice):
                let iceball = Iceball(angle: angle, player: player)
                magics.append(iceball)
                addChild(iceball.node)
            case .A(.earth):
                let stoneWall = StoneWall(player: player, angle: angle)
                addChild(stoneWall.sprite)
            default:
                break
            }
            directionsCombos = []
        } else {
            directionsCombos.append(directions[0])
        }
    }
    
    /// quando a view chamar a cena, esta funçao é a primeira a ser executada.
    ///  é a preparaçao da cena.
    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        myFrame.myVariables.frame = self.size
        myFrame.myVariables.scene = self
        physicsWorld.contactDelegate = self
        background.zPosition = -30
        background.anchorPoint = CGPoint(x: 0.5, y: 0)
        background.size = CGSize(width: frame.width * 3, height: frame.height * 3)
        background.position.y = frame.minY - 185
        addChild(background)
        
        // ------------------------------------------------------------------------
        setupPlayer()

        // ------------------------------------------------------------------------
        setupCamera()
        
        // ------------------------------------------------------------------------
        setupGround2()
        
        // ------------------------------------------------------------------------
        for i in 1...20{
            delayWithSeconds(5.0 * Double(i)) { [self] in
                self.setupSpawn(position: CGPoint(x: frame.midX, y: frame.midY - 20), spriteName: "Spider", idSpawn: i)
            }
        }
        //------------------------------------------------------------------------
        setupButtons()
        
        view.isMultipleTouchEnabled = true
    }
    
    private func setupGround2() {
        let rects = mapInterpreter.rects
        
//        guard let rects = rects else { return }
        for i in rects {
            self.createPlatform(size: i.size, position: i.position, sprite: Constants.randomPlatformSprite())
        }
    }
    
    func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
    
    func didBegin(_ contact:SKPhysicsContact){
        if player.attributes.health <= 0 {
            Constants.notificationCenter.post(name: Notification.Name("playerDeath"), object: nil)
        }
        //lifeFill.xScale = CGFloat(player.attributes.health) / CGFloat(player.attributes.maxHealth)
        
        if (contact.bodyA.node?.name == "platform" && contact.bodyB.node?.name == "Player") || (contact.bodyA.node?.name == "Player" && contact.bodyB.node?.name == "platform") {
            self.jumpCounter = 0
            player.transition(to: .landing)
            player.transition(to: .idle)
        }
        else if (contact.bodyA.node?.name == "platform" && contact.bodyB.node?.name == "Spider") || (contact.bodyA.node?.name == "Spider" && contact.bodyB.node?.name == "platform"){
            for spider in spiders{
                if spider.physicsBody === contact.bodyA || spider.physicsBody === contact.bodyB{
                    if spider.currentState == .attack{
                        var copy = spider
                        copy.transition(to: .walking)
                        copy.attributes.velocity.maxYSpeed /= 100
                        copy.attributes.velocity.maxXSpeed /= 100
                    }
                }
            }
        }
        else if (contact.bodyA.node?.name == "Magic" && contact.bodyB.node?.name == "Spider") || (contact.bodyA.node?.name == "Spider" && contact.bodyB.node?.name == "Magic"){
            for idx in 0..<spiders.count{
                let spider = spiders[idx]
                if spider.physicsBody === contact.bodyA || spider.physicsBody === contact.bodyB{
                    for magic in magics{
                        if magic.physicsBody === contact.bodyA || magic.physicsBody === contact.bodyB{
                            magic.onTouch(touched: &spider.attributes)
                            spider.attributes.velocity.maxYSpeed *= 10
                            spider.attributes.velocity.maxXSpeed *= 10
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                spider.attributes.velocity.maxYSpeed /= 10
                                spider.attributes.velocity.maxXSpeed /= 10
                            }
                            spider.physicsBody.applyImpulse(CGVector(dx: Constants.singleton.spiderSize.width * cos(magic.angle) * 6, dy: Constants.singleton.spiderSize.height * sin(magic.angle) * 6))
                            magic.node.removeFromParent()
                        }
                    }
                }
                if spider.attributes.health<=0 {
                    if spider.currentState != .death{
                        var copy = spider
                        copy.transition(to: .death)
                        spiders.remove(at: idx)
                        delayWithSeconds(spider.despawnTime, completion: {
                            for s in self.spiders{
                                if s.idSpider > spider.idSpider{
                                    s.idSpider -= 1
                                }
                            }
                            //remover aranha da cena
                            spider.sprite.removeFromParent()
                        })
                        //points += 1
                        break
                    }
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        camera?.position = player.position
        for spider in spiders{
            spider.moveAI(player: player.sprite)
        }
        updatePlayerState()
        updateSpidersState()
        
        guard !directionsMovement.isEmpty else { return }
        if player.currentState == .jump || (player.currentState == .airborne && jumpCounter >= 3) {
            directionsMovement.removeAll { dir in
                dir == .up
            }
        }
        
        if directionsMovement.contains(.up) {
            player.transition(to: .jump)
            jumpCounter += 1
        }
        
        player.move(direction: directionsMovement)
        
        if player.sprite.physicsBody!.velocity.dx < 0{
            player.sprite.xScale = -1
        }
        else{
            player.sprite.xScale = 1
        }
    }
    
    func updatePlayerState(){
        if player.currentState == .jump {
            player.physicsBody.collisionBitMask = player.physicsBody.collisionBitMask & (UInt32.max - Constants.singleton.groundMask)
            player.physicsBody.contactTestBitMask = player.physicsBody.contactTestBitMask & (UInt32.max - Constants.singleton.groundMask)
        }
        
        if player.physicsBody.velocity.dy < 0{
            player.transition(to: .airborne)
        }
        
        if player.currentState == .airborne{
            if player.sprite.physicsBody!.collisionBitMask & Constants.singleton.groundMask == 0 {
                var hasCollided = false
                for platform in platforms {
                    if platform.intersects(player.sprite){
                        hasCollided = true
                    }
                }
                if !hasCollided {
                    player.physicsBody.collisionBitMask = player.physicsBody.collisionBitMask + Constants.singleton.groundMask
                    player.physicsBody.contactTestBitMask = player.physicsBody.contactTestBitMask + Constants.singleton.groundMask
                }
            }
        }
        if player.currentState == .idle {
            if player.physicsBody.velocity.dx != 0 {
                player.transition(to: .walking)
            }
        }
        else if player.currentState == .walking {
            if player.physicsBody.velocity.dx == 0 {
                player.transition(to: .idle)
            }
        }
    }
    
    
    func updateSpidersState(){
        for spider in spiders{
            if spider.currentState == .attack{
                if spider.sprite.physicsBody!.collisionBitMask & Constants.singleton.groundMask == 0 {
                    var hasCollided = false
                    for platform in platforms {
                        if platform.intersects(spider.sprite){
                            hasCollided = true
                        }
                    }
                    if !hasCollided {
                        spider.physicsBody.collisionBitMask = spider.physicsBody.collisionBitMask | Constants.singleton.groundMask
                    }
                }
            }
        }
    }
    
    func setupButtons() {
        let buttonRadius: CGFloat = 120
        let positionOffset: CGFloat = 250
        
        // ------------------------------------------------------------------------------------------ movement
        movementInput = SKShapeNode(circleOfRadius: buttonRadius)
        movementInput.position = CGPoint(x: frame.minX + positionOffset, y: frame.minY + positionOffset)
        movementInput.strokeColor = .red
        
        // --------------------------------------------
        movementAnalogic = SKShapeNode(circleOfRadius: 25)
        movementAnalogic.position = CGPoint(x: frame.minX + positionOffset, y: frame.minY + positionOffset)
        movementAnalogic.fillColor = .red
    
        // ------------------------------------------------------------------------------------------ combos
        combosInput = SKShapeNode(circleOfRadius: buttonRadius)
        combosInput.position = CGPoint(x: frame.maxX - positionOffset, y: frame.minY + positionOffset)
        combosInput.strokeColor = .clear
        
        combosInputThreshold = SKShapeNode(circleOfRadius: buttonRadius/4)
        combosInputThreshold.strokeColor = .clear
        
        let earth = SKSpriteNode(texture: Constants.singleton.earthPowerTexture)
        earth.anchorPoint = CGPoint(x: 0, y: 0.5)
        earth.zPosition = 10
        earth.name = "earth"
        combosInput.addChild(earth)
        
        let eletric = SKSpriteNode(texture: Constants.singleton.eletricPowerTexture)
        eletric.anchorPoint = CGPoint(x: 0.5, y: 1)
        eletric.zPosition = 10
        eletric.name = "eletric"
        combosInput.addChild(eletric)
        
        let fire = SKSpriteNode(texture: Constants.singleton.firePowerTexture)
        fire.anchorPoint = CGPoint(x: 1, y: 0.5)
        fire.zPosition = 10
        fire.name = "fire"
        combosInput.addChild(fire)
        
        let ice = SKSpriteNode(texture: Constants.singleton.icePowerTexture)
        ice.anchorPoint = CGPoint(x: 0.5, y: 0)
        ice.zPosition = 10
        ice.name = "ice"
        combosInput.addChild(ice)
        
        for i in combosInput.children {
            i.setScale(Constants.singleton.combosSpritesScale)
            i.alpha = Constants.singleton.combosSpritesAlpha
        }
        
        // --------------------------------------------
        combosAnalogic = SKShapeNode(circleOfRadius: 25)
        combosAnalogic.position = CGPoint(x: frame.maxX - positionOffset, y: frame.minY + positionOffset)
        combosAnalogic.fillColor = .blue
        combosAnalogic.zPosition = 11
        
        // ------------------------------------------------------------------------------------------ add to scene
        camera?.addChild(movementInput)
        camera?.addChild(movementAnalogic)
        
        camera?.addChild(combosInput)
        camera?.addChild(combosAnalogic)
        camera?.addChild(combosInputThreshold)
    }
    //Constants.spiderIdleTexture
    func setupSpawn(position: CGPoint, spriteName: String, idSpawn: Int){
        if(spriteName == "Spider"){
            let enemy = setupSpider(spriteName: "Spider", idSpider: (idSpawn-1))
            enemy.sprite.position = position
            spiders.append(enemy)
            addChild(enemy.sprite)
        }
    }

    func setupCamera() {
        let camera = SKCameraNode()
//        camera.setScale(0.7)
        camera.setScale(1)
        self.camera = camera
        addChild(camera)
    }
    
    func createPlatform(size: CGSize, position: CGPoint, sprite: String){
        let platform = SKSpriteNode(imageNamed: sprite)
        platform.size = size
        // settando o anchor point para ser no meio horizontal e no baixo na vertical
        platform.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        // posicao do platform é zero no x e o mais baixo no y
        platform.position = position
        // criando o physicsbody e settando que nao é dinamico p nenhuma força poder ser aplicada contra ele
        platform.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: size.height * 0.9))
        platform.physicsBody?.isDynamic = false
        platform.name = "platform"
        platform.zPosition = -25
        platform.physicsBody?.categoryBitMask = Constants.singleton.groundMask
        platforms.append(platform)
        platform.physicsBody?.friction = 2
        addChild(platform)
    }
    
    func setupGround(){
        //cria o chao
        createPlatform(size: CGSize(width: frame.width, height: frame.height/4), position: CGPoint(x: 0, y: frame.minY), sprite: "Plataform1")
        // ------------------------------------------------------------------------
        //cria plataforma esquerda
        createPlatform(size: CGSize(width: frame.width/3, height: Constants.singleton.platformsHeight), position: CGPoint(x: frame.minX + frame.width/6, y: frame.midY), sprite: "Plataform3")
        // ------------------------------------------------------------------------
        //cria plataforma direita
        createPlatform(size: CGSize(width: frame.width/3, height: Constants.singleton.platformsHeight), position: CGPoint(x: frame.maxX - frame.width/6, y: frame.midY), sprite: "Plataform2")
        player.sprite.position.y += frame.maxY
        player.setEffect(effect: "DirtParticle")
    }
    
    func setupPlayer(){
        //Creates player and adds it to the scene
        player = Player(sprite: "MagoFrente")
        player.sprite.position.y += frame.midY + frame.midY/2
        addChild(player.sprite)
    }
    
    func setupSpider(spriteName: String, idSpider: Int) -> EnemySpider{
        let spider = EnemySpider(sprite: spriteName, attributes: AttributesInfo(health: 10, defense: 20, weakness: [], velocity: VelocityInfo(xSpeed: 50, ySpeed: 10, maxXSpeed: 200, maxYSpeed: 5000), attackRange: frame.width * 0.3, maxHealth: 10), player: player, idSpider: idSpider)
        return spider
    }
    
//    func setupLifeBar(){
//        camera?.addChild(lifeBar)
//        lifeBar.addChild(lifeFill)
//        lifeFill.anchorPoint = CGPoint(x: 0.0, y: 0.5)
//        lifeFill.position = CGPoint(x: -lifeBar.size.width / 2, y: 0.0)
//        lifeFill.xScale = 1
//    }
}
