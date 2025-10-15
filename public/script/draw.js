export class DrawManager {
    constructor(input) {
        const { drawLayerData, ctx, } = input;
        this.ctx = ctx;
        this.allLayerList = {};
        for (const [name, data] of Object.entries(drawLayerData.list)) {
            this.allLayerList[name] = data;
            this.allLayerList[name].name = name;
        }
        this.layerListInOrder = Object.values(this.allLayerList);
        this.layerListInOrder.sort((a, b) => a.index - b.index);
        this.defaultLayer = drawLayerData.defaultLayer;
    }

    assignComponentToLayer(input) {
        const { objectList, } = input;

        // Initialize buckets for each layer
        const layerBucket = {};
        for (const layer of this.layerListInOrder) {
            layerBucket[layer.name] = [];
        }

        for (const obj of Object.values(objectList)) {
            for (const comp of Object.values(obj.componentList)) {
                if (comp.noAnimationPossible) continue;
                const stateData = comp.animationList[comp.currentState];
                if (!stateData) continue; // skip if no current state

                const layerName = stateData.layer || this.defaultLayer;
                if (!layerBucket[layerName]) continue; // skip if no such layer found

                layerBucket[layerName].push(comp);
            }
        }
        return { layerBucket, };
    }

    draw(input) {
        this.drawDebug(input);

        const { camera, objectList } = input;
        const ctx = this.ctx;

        const { layerBucket } = this.assignComponentToLayer({ objectList, });
        for (const layer of this.layerListInOrder) {
            const componentList = layerBucket[layer.name] || [];
            for (const comp of componentList) {
                if (comp.noAnimationPossible) continue;

                const stateName = comp.currentState;
                const stateData = comp.animationList[stateName];
                const frameIndex = comp.frameIndex[stateName] || 0;
                const img = stateData.imageList[frameIndex];
                if (!img) continue;

                const drawX = comp.x - (camera?.x || 0);
                const drawY = comp.y - (camera?.y || 0);

                if (comp.isFlipped) {
                    ctx.save();
                    ctx.scale(-1, 1);
                    ctx.drawImage(img, -drawX - stateData.width, drawY, stateData.width, stateData.height);
                    ctx.restore();
                } else {
                    ctx.drawImage(img, drawX, drawY);
                }
            }
        }
    }

    drawDebug(input) {
        const { camera, mapLimit, colony, bgImage, } = input;
        const ctx = this.ctx;
        // Draw black background
        ctx.fillStyle = 'black';
        ctx.fillRect(0, 0, camera.width, camera.height);

        // Draw background
        ctx.drawImage(
            bgImage,
            0, 0, bgImage.width, bgImage.height,
            -camera.x, -camera.y,
            colony.width, colony.height
        );

        // Draw edges
        ctx.strokeStyle = 'yellow';
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(mapLimit.left - camera.x, 0 - camera.y);
        ctx.lineTo(mapLimit.left - camera.x, colony.height - camera.y);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(mapLimit.right - camera.x, 0 - camera.y);
        ctx.lineTo(mapLimit.right - camera.x, colony.height - camera.y);
        ctx.stroke();

        // Draw ground lines
        ctx.strokeStyle = 'green';
        for (const level of colony.levelListInOrder) {
            ctx.beginPath();
            ctx.moveTo(mapLimit.left - camera.x, level.groundY - camera.y);
            ctx.lineTo(mapLimit.right - camera.x, level.groundY - camera.y);
            ctx.stroke();
        }
    }
}