pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import Quickshell;
import QtQuick;

/**
 * A service for interacting with various booru APIs.
 */
Singleton {
    id: root
    property Component booruResponseDataComponent: BooruResponseData {}

    signal tagSuggestion(string query, var suggestions)
    signal responseFinished()

    property string failMessage: Translation.tr("That didn't work. Tips:\n- Check your tags and NSFW settings\n- If you don't have a tag in mind, type a page number")
    property var responses: []
    property int runningRequests: 0
    property var defaultUserAgent: Config.options?.networking?.userAgent || "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
    property var providerList: Object.keys(providers).filter(provider => provider !== "system" && providers[provider].api)
    property var providers: {
        "system": { "name": Translation.tr("System") },
        "yandere": {
            "name": "yande.re",
            "url": "https://yande.re",
            "api": "https://yande.re/post.json",
            "description": Translation.tr("All-rounder | Good quality, decent quantity"),
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://yande.re/tag.json?order=count&limit=10&name={{query}}*",
            "tagMapFunc": (response) => {
                return response.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "konachan": {
            "name": "Konachan",
            "url": "https://konachan.net",
            "api": "https://konachan.net/post.json",
            "description": Translation.tr("For desktop wallpapers | Good quality"),
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://konachan.net/tag.json?order=count&limit=10&name={{query}}*",
            "tagMapFunc": (response) => {
                return response.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "zerochan": {
            "name": "Zerochan",
            "url": "https://www.zerochan.net",
            "api": "https://www.zerochan.net/?json",
            "description": Translation.tr("Clean stuff | Excellent quality, no NSFW"),
            "mapFunc": (response) => {
                response = response.items
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags.join(" "),
                        "rating": "safe", // Zerochan doesn't have nsfw
                        "is_nsfw": false,
                        "md5": item.md5,
                        "preview_url": item.thumbnail,
                        "sample_url": item.thumbnail,
                        "file_url": item.thumbnail,
                        "file_ext": "avif",
                        "source": getWorkingImageSource(item.source) ?? item.thumbnail,
                        "character": item.tag
                    }
                })
            }
        },
        "danbooru": {
            "name": "Danbooru",
            "url": "https://danbooru.donmai.us",
            "api": "https://danbooru.donmai.us/posts.json",
            "description": Translation.tr("The popular one | Best quantity, but quality can vary wildly"),
            "mapFunc": (response) => {
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.image_width,
                        "height": item.image_height,
                        "aspect_ratio": item.image_width / item.image_height,
                        "tags": item.tag_string,
                        "rating": item.rating,
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_file_url,
                        "sample_url": item.file_url ?? item.large_file_url,
                        "file_url": item.large_file_url,
                        "file_ext": item.file_ext,
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://danbooru.donmai.us/tags.json?limit=10&search[name_matches]={{query}}*",
            "tagMapFunc": (response) => {
                return response.map(item => {
                    return {
                        "name": item.name,
                        "count": item.post_count
                    }
                })
            }
        },
        "gelbooru": {
            "name": "Gelbooru",
            "url": "https://gelbooru.com",
            "api": "https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1",
            "description": Translation.tr("The hentai one | Great quantity, a lot of NSFW, quality varies wildly"),
            "mapFunc": (response) => {
                response = response.post
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags,
                        "rating": item.rating.replace('general', 's').charAt(0),
                        "is_nsfw": (item.rating != 's'),
                        "md5": item.md5,
                        "preview_url": item.preview_url,
                        "sample_url": item.sample_url ?? item.file_url,
                        "file_url": item.file_url,
                        "file_ext": item.file_url.split('.').pop(),
                        "source": getWorkingImageSource(item.source) ?? item.file_url,
                    }
                })
            },
            "tagSearchTemplate": "https://gelbooru.com/index.php?page=dapi&s=tag&q=index&json=1&orderby=count&limit=10&name_pattern={{query}}%",
            "tagMapFunc": (response) => {
                return response.tag.map(item => {
                    return {
                        "name": item.name,
                        "count": item.count
                    }
                })
            }
        },
        "rule34": {
            "name": "rule34.xxx",
            "url": "https://api.rule34.xxx",
            "api": "https://api.rule34.xxx/index.php?page=dapi&s=post&q=index",
            "description": Translation.tr("The other one | Gelbooru-compatible, set apiKey/userId in config"),
            "manualParseFunc": (responseText) => {
                // rule34 post API returns XML; json=1 breaks the response
                const postRegex = /<post\b([^]*?)\/>/g
                const results = []
                let postMatch
                while ((postMatch = postRegex.exec(responseText)) !== null) {
                    const attrs = {}
                    const attrRegex = /(\w+)="([^"]*)"/g
                    let attrMatch
                    while ((attrMatch = attrRegex.exec(postMatch[1])) !== null) {
                        attrs[attrMatch[1]] = attrMatch[2]
                    }
                    const width = parseInt(attrs.width, 10) || 0
                    const height = parseInt(attrs.height, 10) || 1
                    const rating = attrs.rating || 'e'
                    results.push({
                        "id": attrs.id,
                        "width": width,
                        "height": height,
                        "aspect_ratio": width / height,
                        "tags": attrs.tags || "",
                        "rating": rating,
                        "is_nsfw": (rating != 's'),
                        "md5": attrs.md5 || "",
                        "preview_url": attrs.preview_url,
                        "sample_url": attrs.sample_url || attrs.file_url,
                        "file_url": attrs.file_url,
                        "file_ext": attrs.file_url ? attrs.file_url.split('.').pop() : "",
                        "source": getWorkingImageSource(attrs.source) || attrs.file_url || "",
                    })
                }
                return results
            },
            "tagSearchTemplate": "https://api.rule34.xxx/autocomplete.php?q={{query}}",
            "tagMapFunc": (response) => {
                return response.map(item => {
                    return {
                        "name": item.value,
                        "count": parseInt(item.label.match(/\((\d+)\)/)?.[1] ?? "0", 10)
                    }
                })
            }
        },
        "waifu.im": {
            "name": "waifu.im",
            "url": "https://waifu.im",
            "api": "https://api.waifu.im/images",
            "description": Translation.tr("Waifus only | Excellent quality, limited quantity"),
            "mapFunc": (response) => {
                response = response.items
                return response.map(item => {
                    return {
                        "id": item.id,
                        "width": item.width,
                        "height": item.height,
                        "aspect_ratio": item.width / item.height,
                        "tags": item.tags.map(tag => {return tag.name}).join(" "),
                        "rating": item.isNsfw ? "e" : "s",
                        "is_nsfw": item.isNsfw,
                        "md5": item.md5,
                        "preview_url": item.sample_url ?? item.url, // preview_url just says access denied (maybe i fucked up and sent too many requests idk)
                        "sample_url": item.url,
                        "file_url": item.url,
                        "file_ext": item.extension,
                        "source": getWorkingImageSource(item.source) ?? item.url,
                    }
                })
            },
            "tagSearchTemplate": "https://api.waifu.im/tags?Name={{query}}",
            "tagMapFunc": (response) => {
                return response.items.map(item => {return {"name": item.name}})
            }
        },
        "t.alcy.cc": {
            "name": "Alcy",
            "url": "https://t.alcy.cc",
            "api": "https://t.alcy.cc/",
            "description": Translation.tr("Large images | God tier quality, no NSFW."),
            "fixedTags": [
                {
                    "name": "ycy",
                    "count": "General"
                },
                {
                    "name": "moez",
                    "count": "Moe"
                },
                {
                    "name": "ysz",
                    "count": "Genshin Impact"
                },
                {
                    "name": "fj",
                    "count": "Landscape"
                },
                {
                    "name": "bd",
                    "count": "Girl on white background"
                },
                {
                    "name": "xhl",
                    "count": "Shiggy"
                },
            ],
            "manualParseFunc": (responseText) => {
                // Alcy just returns image links, each on a new line
                const lines = responseText.trim().split('\n');
                return lines.map(line => {
                    return {
                        "id": Qt.md5(line),
                        // Alcy doesn't provide dimensions and images are often of god resolution
                        "width": 1000,
                        "height": 1000,
                        "aspect_ratio": 1,
                        "tags": "[no tags]",
                        "rating": "s",
                        "is_nsfw": false,
                        "md5": Qt.md5(line),
                        "preview_url": line,
                        "sample_url": line,
                        "file_url": line,
                        "file_ext": line.split('.').pop(),
                        "source": "",
                    }
                });
            },
        }
    }
    property var currentProvider: Persistent.states.booru.provider

    function getWorkingImageSource(url) {
        if (url?.includes('pximg.net')) {
            return `https://www.pixiv.net/en/artworks/${url.substring(url.lastIndexOf('/') + 1).replace(/_p\d+\.(png|jpg|jpeg|gif)$/, '')}`;
        }
        return url;
    }
    
    function setProvider(provider) {
        provider = provider.toLowerCase()
        if (providerList.indexOf(provider) !== -1) {
            Persistent.states.booru.provider = provider
            root.addSystemMessage(Translation.tr("Provider set to ") + providers[provider].name
                + (provider == "zerochan" ? Translation.tr(". Notes for Zerochan:\n- You must enter a color\n- Set your zerochan username in `sidebar.booru.zerochan.username` config option. You [might be banned for not doing so](https://www.zerochan.net/api#:~:text=The%20request%20may%20still%20be%20completed%20successfully%20without%20this%20custom%20header%2C%20but%20your%20project%20may%20be%20banned%20for%20being%20anonymous.)!") : ""))
        } else {
            root.addSystemMessage(Translation.tr("Invalid API provider. Supported: \n- ") + providerList.join("\n- "))
        }
    }

    function clearResponses() {
        responses = []
    }

    function addToBlacklist(tags) {
        const current = Persistent.states.booru.blacklist ?? []
        const newTags = tags.split(/\s+/).filter(tag => tag.length > 0 && !current.includes(tag))
        if (newTags.length > 0) {
            Persistent.states.booru.blacklist = [...current, ...newTags]
            root.addSystemMessage(Translation.tr("Added to blacklist: ") + newTags.join(", "))
        }
    }

    function removeFromBlacklist(tag) {
        const current = Persistent.states.booru.blacklist ?? []
        Persistent.states.booru.blacklist = current.filter(t => t !== tag)
        root.addSystemMessage(Translation.tr("Removed from blacklist: ") + tag)
    }

    function clearBlacklist() {
        Persistent.states.booru.blacklist = []
        root.addSystemMessage(Translation.tr("Blacklist cleared"))
    }

    function getBlacklist() {
        return Persistent.states.booru.blacklist ?? []
    }

    function addSystemMessage(message) {
        responses = [...responses, root.booruResponseDataComponent.createObject(null, {
            "provider": "system",
            "tags": [],
            "page": -1,
            "images": [],
            "message": `${message}`
        })]
    }

    function appendAuthParams(provider, params) {
        const rule34Config = Config.options?.sidebar?.booru?.rule34
        if (currentProvider === "rule34") {
            const apiKey = rule34Config?.apiKey
            const userId = rule34Config?.userId
            if (apiKey && userId) {
                params.push("api_key=" + encodeURIComponent(apiKey))
                params.push("user_id=" + encodeURIComponent(userId))
            }
        }
    }

    function constructRequestUrl(tags, nsfw=true, limit=20, page=1) {
        var provider = providers[currentProvider]
        var baseUrl = provider.api
        var url = baseUrl
        var tagString = tags.join(" ")
        // Apply blacklist from persistent state + config
        const blacklist = Persistent.states.booru.blacklist ?? []
        const configBlacklist = Config.options?.sidebar?.booru?.[currentProvider]?.blacklist
            ?? Config.options?.sidebar?.booru?.blacklist
            ?? []
        const allBlacklist = [...new Set([...blacklist, ...configBlacklist])]
        if (allBlacklist.length > 0) {
            const negTags = allBlacklist.map(tag => "-" + tag).join(" ")
            tagString = tagString ? tagString + " " + negTags : negTags
        }
        if (!nsfw && !(["zerochan", "waifu.im", "t.alcy.cc"].includes(currentProvider))) {
            if (currentProvider == "gelbooru") 
                tagString += " rating:general";
            else 
                tagString += " rating:safe";
        }
        var params = []
        // Tags & limit
        if (currentProvider === "zerochan") {
            params.push("c=" + tagString) // zerochan doesn't have search in api, so we use color
            params.push("l=" + limit)
            params.push("s=" + "fav")
            params.push("t=" + 1)
            params.push("p=" + page)
        }
        else if (currentProvider === "waifu.im") {
            var tagsArray = tagString.split(" ");
            tagsArray.forEach(tag => {
                params.push("IncludedTags=" + encodeURIComponent(tag.toLowerCase()));
            });
            params.push("PageSize=" + Math.min(limit, 30)) // Only admin can do > 30
            params.push("IsNsfw=" + (nsfw ? "All" : "False")) // null is random
        }
        else if (currentProvider === "t.alcy.cc") {
            url += tagString
            params.push("json")
            params.push("quantity=" + limit)
        }
        else {
            params.push("tags=" + encodeURIComponent(tagString))
            params.push("limit=" + limit)
            if (currentProvider == "gelbooru" || currentProvider == "rule34") {
                params.push("pid=" + page)
            }
            else {
                params.push("page=" + page)
            }
        }
        appendAuthParams(provider, params)
        if (baseUrl.indexOf("?") === -1) {
            url += "?" + params.join("&")
        } else {
            url += "&" + params.join("&")
        }
        return url
    }

    property var _pendingCurlRequests: ({})
    property int _curlRequestId: 0

    property var _curlProcesses: ({})

    function _curlOnSuccess(id, text) {
        const pending = root._pendingCurlRequests[id]
        if (pending) {
            delete root._pendingCurlRequests[id]
            if (root._curlProcesses[id]) {
                root._curlProcesses[id].destroy()
                delete root._curlProcesses[id]
            }
            pending.onSuccess(text)
        }
    }

    function _curlOnError(id, error) {
        const pending = root._pendingCurlRequests[id]
        if (pending) {
            delete root._pendingCurlRequests[id]
            if (root._curlProcesses[id]) {
                root._curlProcesses[id].destroy()
                delete root._curlProcesses[id]
            }
            pending.onError(error)
        }
    }

    function makeCurlRequest(requestUrl, onSuccess, onError) {
        const id = root._curlRequestId++
        root._pendingCurlRequests[id] = { onSuccess, onError }
        const escapedUrl = String(requestUrl).replace(/'/g, "'\\''")
        const escapedUa = String(defaultUserAgent).replace(/'/g, "'\\''")
        const qml = `
            import Quickshell.Io
            Process {
                id: curlProc${id}
                running: true
                command: ["bash", "-c", "curl -sS -m 30 -A '${escapedUa}' '${escapedUrl}'"]
                stdout: StdioCollector {
                    id: collector${id}
                    onStreamFinished: root._curlOnSuccess(${id}, collector${id}.text)
                }
                onExited: (exitCode, exitStatus) => {
                    if (exitCode !== 0)
                        root._curlOnError(${id}, "curl exit code: " + exitCode)
                }
            }
        `
        const proc = Qt.createQmlObject(qml, root, "BooruCurlRequest")
        root._curlProcesses[id] = proc
    }

    function finishBooruResponse(newResponse, responseText) {
        try {
            const provider = providers[currentProvider]
            let response;
            if (provider.manualParseFunc) {
                response = provider.manualParseFunc(responseText)
            } else {
                response = JSON.parse(responseText)
                response = provider.mapFunc(response)
            }
            newResponse.images = response
            newResponse.message = response.length > 0 ? "" : root.failMessage
        } catch (e) {
            console.log("[Booru] Failed to parse response: " + e)
            newResponse.message = root.failMessage
        } finally {
            root.runningRequests--;
            root.responses = [...root.responses, newResponse]
            root.responseFinished()
        }
    }

    function makeRequest(tags, nsfw=false, limit=20, page=1) {
        var url = constructRequestUrl(tags, nsfw, limit, page)
        console.log("[Booru] Making request to " + url)

        const newResponse = root.booruResponseDataComponent.createObject(null, {
            "provider": currentProvider,
            "tags": tags,
            "page": page,
            "images": [],
            "message": ""
        })

        if (currentProvider === "rule34") {
            root.runningRequests++;
            makeCurlRequest(url,
                (responseText) => { finishBooruResponse(newResponse, responseText) },
                (error) => {
                    console.log("[Booru] Curl request failed: " + error)
                    newResponse.message = root.failMessage
                    root.runningRequests--;
                    root.responses = [...root.responses, newResponse]
                    root.responseFinished()
                }
            )
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                finishBooruResponse(newResponse, xhr.responseText)
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
                newResponse.message = root.failMessage
                root.runningRequests--;
                root.responses = [...root.responses, newResponse]
                root.responseFinished()
            }
        }

        try {
            // Required for danbooru and konachan
            if (["danbooru", "konachan"].includes(currentProvider)) {
                xhr.setRequestHeader("User-Agent", defaultUserAgent)
            }
            else if (currentProvider == "zerochan") {
                const userAgent = Config.options?.sidebar?.booru?.zerochan?.username ? `Desktop sidebar booru viewer - username: ${Config.options.sidebar.booru.zerochan.username}` : defaultUserAgent
                xhr.setRequestHeader("User-Agent", userAgent)
            }
            root.runningRequests++;
            xhr.send()
        } catch (error) {
            console.log("Could not set User-Agent:", error)
        } 
    }

    property var currentTagRequest: null
    function triggerTagSearch(query) {
        if (currentTagRequest) {
            currentTagRequest.abort();
        }

        var provider = providers[currentProvider]
        if (provider.fixedTags) {
            root.tagSuggestion(query, provider.fixedTags)
            return provider.fixedTags;
        } else if (!provider.tagSearchTemplate) {
            return
        }
        var url = provider.tagSearchTemplate.replace("{{query}}", encodeURIComponent(query))
        const authParams = []
        appendAuthParams(provider, authParams)
        if (authParams.length > 0) {
            url += "&" + authParams.join("&")
        }

        if (currentProvider === "rule34") {
            makeCurlRequest(url,
                (responseText) => {
                    try {
                        var response = JSON.parse(responseText)
                        response = provider.tagMapFunc(response)
                        root.tagSuggestion(query, response)
                    } catch (e) {
                        console.log("[Booru] Failed to parse tag response: " + e)
                    }
                },
                (error) => {
                    console.log("[Booru] Curl tag request failed: " + error)
                }
            )
            return
        }

        var xhr = new XMLHttpRequest()
        currentTagRequest = xhr
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                currentTagRequest = null
                try {
                    var response = provider.manualTagParseFunc ? provider.manualTagParseFunc(xhr.responseText) : JSON.parse(xhr.responseText)
                    if (!provider.manualTagParseFunc) response = provider.tagMapFunc(response)
                    root.tagSuggestion(query, response)
                } catch (e) {
                    console.log("[Booru] Failed to parse response: " + e)
                }
            }
            else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[Booru] Request failed with status: " + xhr.status)
            }
        }

        try {
            // Required for danbooru and konachan
            if (["danbooru", "konachan"].includes(currentProvider)) {
                xhr.setRequestHeader("User-Agent", defaultUserAgent)
            }
            xhr.send()
        } catch (error) {
            console.log("Could not set User-Agent:", error)
        } 
    }
}

