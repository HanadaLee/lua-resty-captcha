describe("captcha generation", function()
    local captcha = require("resty.captcha")

    it("draws text and returns a JPEG", function()
        local cap = captcha.new()
        assert.is_true(cap:font("examples/Vera.ttf"))
        assert.is_true(cap:string("ABC123"))
        assert.is_true(cap:generate())

        local non_background_pixels = 0
        for y = 0, 44 do
            for x = 0, 239 do
                if cap.im:getPixel(x, y) ~= 0xffffff then
                    non_background_pixels = non_background_pixels + 1
                end
            end
        end
        assert.is_true(non_background_pixels > 100)

        local blob, err = cap:jpegStr(70)
        assert.is_nil(err)
        assert.is_true(#blob > 4)
        assert.are_equal("\255\216", blob:sub(1, 2))
        assert.are_equal("\255\217", blob:sub(-2))
    end)
end)
