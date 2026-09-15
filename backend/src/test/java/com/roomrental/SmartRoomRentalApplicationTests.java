package com.roomrental;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(classes = SmartRoomRentalApplication.class)
@ActiveProfiles("test")
@org.springframework.context.annotation.Import(SmartRoomRentalApplicationTests.TestConfig.class)
class SmartRoomRentalApplicationTests {

	@org.springframework.boot.test.context.TestConfiguration
	static class TestConfig {
		@org.springframework.context.annotation.Bean
		public org.springframework.data.redis.core.StringRedisTemplate stringRedisTemplate() {
			return org.mockito.Mockito.mock(org.springframework.data.redis.core.StringRedisTemplate.class);
		}
	}

	@Test
	void contextLoads() {
	}

}