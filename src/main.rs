#![no_std]
#![no_main]

use defmt::*;
use defmt_rtt as _;
use embassy_executor::Spawner;
use embassy_stm32::{
    gpio::{Level, Output, Speed},
    spi::{Config, Spi},
    time::Hertz,
};
use embassy_time::{Delay, Timer};
use embedded_hal_async::spi::SpiDevice;
use panic_probe as _;

#[embassy_executor::main]
async fn main(_spawner: Spawner) {
    let peripherals = embassy_stm32::init(Default::default());
    let mut spi_config = Config::default();
    spi_config.frequency = Hertz(1_000_000);

    let spi = Spi::new(
        peripherals.SPI3,
        peripherals.PB3,
        peripherals.PB5,
        peripherals.PB4,
        peripherals.DMA1_CH5,
        peripherals.DMA1_CH0,
        spi_config,
    );
    let cs = Output::new(peripherals.PA4, Level::High, Speed::VeryHigh);
    let mut spi_driver = embedded_hal_bus::spi::ExclusiveDevice::new(spi, cs, Delay)
        .expect("Failed to create SPI Driver");

    let mut spi_transbuf_rx: [u8; 4] = [0x00; 4];
    let spi_transbuf_tx = &[0x00, 0x11, 0x22, 0x33];
    loop {
        spi_driver.write(spi_transbuf_tx).await.unwrap();
        spi_driver
            .transfer(&mut spi_transbuf_rx, spi_transbuf_tx)
            .await
            .unwrap();
        Timer::after_millis(10).await;
    }
}
